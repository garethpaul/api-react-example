import { act, render, screen, waitFor } from '@testing-library/react';
import { vi } from 'vitest';
import App from './App';
import Photos, {
  isJsonContentType,
  MAX_PHOTO_RESPONSE_BYTES,
  MAX_PHOTOS,
  PHOTO_ENDPOINT,
  PHOTO_REQUEST_TIMEOUT_MS,
  readBoundedPhotoJson,
} from './components/Photos';

const photos = [
  {
    id: 1,
    title: 'First photo',
    thumbnailUrl: 'https://example.com/first.jpg',
  },
  {
    id: 2,
    title: 'Second photo',
    thumbnailUrl: 'https://example.com/second.jpg',
  },
];
const originalAbortController = global.AbortController;

const utf8 = new TextEncoder();

function jsonHeaders(
  contentType = 'application/json; charset=utf-8',
  contentLength = null,
) {
  return {
    get: vi.fn((name) => {
      const normalizedName = name.toLowerCase();
      if (normalizedName === 'content-type') {
        return contentType;
      }
      if (normalizedName === 'content-length') {
        return contentLength;
      }
      return null;
    }),
  };
}

function mockFetchSuccess(data = photos) {
  const bytes = utf8.encode(JSON.stringify(data));
  global.fetch = vi.fn().mockResolvedValue({
    ok: true,
    headers: jsonHeaders(
      'application/json; charset=utf-8',
      String(bytes.byteLength),
    ),
    arrayBuffer: vi.fn().mockResolvedValue(bytes.buffer),
  });
}

function streamingJsonResponse(chunks, contentLength = null) {
  const read = vi.fn();
  chunks.forEach((chunk) => {
    read.mockResolvedValueOnce({ done: false, value: chunk });
  });
  read.mockResolvedValueOnce({ done: true, value: undefined });
  const reader = {
    read,
    cancel: vi.fn().mockResolvedValue(undefined),
    releaseLock: vi.fn(),
  };
  return {
    response: {
      headers: jsonHeaders('application/json', contentLength),
      body: { getReader: vi.fn(() => reader) },
    },
    reader,
  };
}

afterEach(() => {
  vi.restoreAllMocks();
  delete global.fetch;
  global.AbortController = originalAbortController;
  vi.useRealTimers();
});

test('renders the photo list heading from the app shell', async () => {
  mockFetchSuccess();

  render(<App />);

  expect(
    screen.getByRole('heading', { name: /photo list/i }),
  ).toBeInTheDocument();
  expect(await screen.findByText('First photo')).toBeInTheDocument();
});

test('loads and renders photos from the placeholder API', async () => {
  mockFetchSuccess();

  render(<Photos />);

  expect(screen.getByRole('status')).toHaveTextContent('Loading photos...');
  if (global.AbortController) {
    expect(global.fetch).toHaveBeenCalledWith(
      PHOTO_ENDPOINT,
      expect.objectContaining({ signal: expect.any(Object) }),
    );
  } else {
    expect(global.fetch).toHaveBeenCalledWith(PHOTO_ENDPOINT);
  }
  expect(await screen.findByText('First photo')).toBeInTheDocument();
  expect(screen.getByAltText('Second photo')).toHaveAttribute(
    'src',
    'https://example.com/second.jpg',
  );
});

test('loads thumbnails lazily without sending a referrer', async () => {
  mockFetchSuccess();

  render(<Photos />);

  const image = await screen.findByAltText('First photo');
  expect(image).toHaveAttribute('loading', 'lazy');
  expect(image).toHaveAttribute('referrerpolicy', 'no-referrer');
});

test('renders an error state when the photo request fails', async () => {
  global.fetch = vi.fn().mockRejectedValue(new Error('network failed'));

  render(<Photos />);

  expect(await screen.findByRole('alert')).toHaveTextContent(
    'Unable to load photos.',
  );
});

test('renders an error state when the photo request is not ok', async () => {
  global.fetch = vi.fn().mockResolvedValue({
    ok: false,
    status: 500,
  });

  render(<Photos />);

  expect(await screen.findByRole('alert')).toHaveTextContent(
    'Unable to load photos.',
  );
});

test('recognizes explicit JSON response media types', () => {
  expect(isJsonContentType('application/json')).toBe(true);
  expect(isJsonContentType(' Application/JSON ; Charset=UTF-8 ')).toBe(true);
  expect(isJsonContentType('application/problem+json')).toBe(true);
  expect(
    isJsonContentType('application/vnd.example.photo+json; version=1'),
  ).toBe(true);
  expect(isJsonContentType('text/json')).toBe(false);
  expect(isJsonContentType('application/jsonp')).toBe(false);
  expect(isJsonContentType(null)).toBe(false);
});

test('rejects a successful photo response without a content type', async () => {
  const arrayBuffer = vi.fn();
  global.fetch = vi.fn().mockResolvedValue({
    ok: true,
    headers: jsonHeaders(null),
    arrayBuffer,
  });

  render(<Photos />);

  expect(await screen.findByRole('alert')).toHaveTextContent(
    'Unable to load photos.',
  );
  expect(arrayBuffer).not.toHaveBeenCalled();
});

test('rejects a successful non-JSON photo response before parsing', async () => {
  const arrayBuffer = vi.fn();
  global.fetch = vi.fn().mockResolvedValue({
    ok: true,
    headers: jsonHeaders('text/html; charset=utf-8'),
    arrayBuffer,
  });

  render(<Photos />);

  expect(await screen.findByRole('alert')).toHaveTextContent(
    'Unable to load photos.',
  );
  expect(arrayBuffer).not.toHaveBeenCalled();
});

test('rejects a declared oversized photo response before reading', async () => {
  const arrayBuffer = vi.fn();
  const response = {
    headers: jsonHeaders(
      'application/json',
      String(MAX_PHOTO_RESPONSE_BYTES + 1),
    ),
    arrayBuffer,
  };

  await expect(readBoundedPhotoJson(response)).rejects.toThrow(
    'Photo response body is too large.',
  );
  expect(arrayBuffer).not.toHaveBeenCalled();
});

test('cancels a streamed photo response when its byte limit is crossed', async () => {
  const { response, reader } = streamingJsonResponse([
    new Uint8Array(MAX_PHOTO_RESPONSE_BYTES),
    new Uint8Array(1),
  ]);

  await expect(readBoundedPhotoJson(response)).rejects.toThrow(
    'Photo response body is too large.',
  );
  expect(reader.cancel).toHaveBeenCalledTimes(1);
  expect(reader.releaseLock).toHaveBeenCalledTimes(1);
});

test('releases a streamed photo reader after successful parsing', async () => {
  const { response, reader } = streamingJsonResponse([
    utf8.encode('['),
    utf8.encode(']'),
  ]);

  await expect(readBoundedPhotoJson(response)).resolves.toEqual([]);
  expect(reader.cancel).not.toHaveBeenCalled();
  expect(reader.releaseLock).toHaveBeenCalledTimes(1);
});

test('rejects an oversized photo response through the array buffer fallback', async () => {
  const response = {
    headers: jsonHeaders('application/json', String(MAX_PHOTO_RESPONSE_BYTES)),
    arrayBuffer: vi
      .fn()
      .mockResolvedValue(new Uint8Array(MAX_PHOTO_RESPONSE_BYTES + 1).buffer),
  };

  await expect(readBoundedPhotoJson(response)).rejects.toThrow(
    'Photo response body is too large.',
  );
});

test('rejects malformed UTF-8 photo response bytes', async () => {
  const response = {
    headers: jsonHeaders('application/json', '1'),
    arrayBuffer: vi.fn().mockResolvedValue(new Uint8Array([0x80]).buffer),
  };

  await expect(readBoundedPhotoJson(response)).rejects.toThrow(TypeError);
});

test('accepts valid JSON exactly at the photo response byte limit', async () => {
  const json = `${' '.repeat(MAX_PHOTO_RESPONSE_BYTES - 2)}[]`;
  const bytes = utf8.encode(json);
  const response = {
    headers: jsonHeaders('application/json', String(bytes.byteLength)),
    arrayBuffer: vi.fn().mockResolvedValue(bytes.buffer),
  };

  expect(bytes.byteLength).toBe(MAX_PHOTO_RESPONSE_BYTES);
  await expect(readBoundedPhotoJson(response)).resolves.toEqual([]);
});

test('does not update state after unmounting during photo load', async () => {
  let resolveBody;
  const arrayBuffer = vi.fn(
    () =>
      new Promise((resolve) => {
        resolveBody = resolve;
      }),
  );
  global.fetch = vi.fn().mockResolvedValue({
    ok: true,
    headers: jsonHeaders('application/json', '2'),
    arrayBuffer,
  });
  const setStateSpy = vi.spyOn(Photos.prototype, 'setState');

  const { unmount } = render(<Photos />);

  await waitFor(() => expect(arrayBuffer).toHaveBeenCalled());
  unmount();

  await act(async () => {
    resolveBody(utf8.encode(JSON.stringify(photos)).buffer);
  });

  expect(setStateSpy).not.toHaveBeenCalled();
});

test('aborts pending photo fetch after unmount', () => {
  const abort = vi.fn();
  const signal = {};
  global.AbortController = vi.fn(function MockAbortController() {
    this.abort = abort;
    this.signal = signal;
  });
  global.fetch = vi.fn(() => new Promise(() => {}));

  const { unmount } = render(<Photos />);

  expect(global.fetch).toHaveBeenCalledWith(PHOTO_ENDPOINT, { signal });

  unmount();

  expect(abort).toHaveBeenCalledTimes(1);
});

test('ignores a superseded request after the same instance remounts', async () => {
  let rejectFirstRequest;
  global.fetch = vi
    .fn()
    .mockImplementationOnce(
      () =>
        new Promise((_, reject) => {
          rejectFirstRequest = reject;
        }),
    )
    .mockResolvedValueOnce({
      ok: true,
      headers: jsonHeaders(
        'application/json',
        String(utf8.encode(JSON.stringify(photos)).byteLength),
      ),
      arrayBuffer: vi
        .fn()
        .mockResolvedValue(utf8.encode(JSON.stringify(photos)).buffer),
    });
  const component = new Photos({});
  component.setState = vi.fn();

  component.componentDidMount();
  component.componentWillUnmount();
  component.componentDidMount();

  await waitFor(() =>
    expect(component.setState).toHaveBeenCalledWith({
      photos: photos.map((photo) => ({ ...photo, id: String(photo.id) })),
      loading: false,
      error: null,
    }),
  );

  await act(async () => {
    rejectFirstRequest(new Error('superseded request failed'));
  });

  expect(component.setState).toHaveBeenCalledTimes(1);
  component.componentWillUnmount();
});

test('aborts and renders an error when the photo request times out', async () => {
  vi.useFakeTimers();
  const abort = vi.fn();
  const signal = {};
  global.AbortController = vi.fn(function MockAbortController() {
    this.abort = abort;
    this.signal = signal;
  });
  global.fetch = vi.fn(() => new Promise(() => {}));

  render(<Photos />);

  await act(async () => {
    await vi.advanceTimersByTimeAsync(PHOTO_REQUEST_TIMEOUT_MS);
  });

  expect(abort).toHaveBeenCalledTimes(1);
  expect(screen.getByRole('alert')).toHaveTextContent('Unable to load photos.');
});

test('times out while parsing photos without abort support', async () => {
  vi.useFakeTimers();
  global.AbortController = undefined;
  global.fetch = vi.fn().mockResolvedValue({
    ok: true,
    headers: jsonHeaders('application/json', '2'),
    arrayBuffer: vi.fn(() => new Promise(() => {})),
  });

  render(<Photos />);

  await act(async () => {
    await vi.advanceTimersByTimeAsync(PHOTO_REQUEST_TIMEOUT_MS);
  });

  expect(screen.getByRole('alert')).toHaveTextContent('Unable to load photos.');
});

test('renders an error state when the photo response is not an array', async () => {
  mockFetchSuccess({ unexpected: true });

  render(<Photos />);

  expect(await screen.findByRole('alert')).toHaveTextContent(
    'Unable to load photos.',
  );
});

test('renders an error state when a photo item is missing render fields', async () => {
  mockFetchSuccess([{ id: 1, title: 'Missing thumbnail' }]);

  render(<Photos />);

  expect(await screen.findByRole('alert')).toHaveTextContent(
    'Unable to load photos.',
  );
  expect(screen.queryByText('Missing thumbnail')).not.toBeInTheDocument();
});

test('renders an error state when photo ids are duplicated', async () => {
  mockFetchSuccess([
    {
      id: 1,
      title: 'First duplicate',
      thumbnailUrl: 'https://example.com/first.jpg',
    },
    {
      id: '1',
      title: 'Second duplicate',
      thumbnailUrl: 'https://example.com/second.jpg',
    },
  ]);

  render(<Photos />);

  expect(await screen.findByRole('alert')).toHaveTextContent(
    'Unable to load photos.',
  );
  expect(screen.queryByText('First duplicate')).not.toBeInTheDocument();
  expect(screen.queryByText('Second duplicate')).not.toBeInTheDocument();
});

test('renders an error state when a photo id is not a string or finite number', async () => {
  mockFetchSuccess([
    {
      id: { value: 1 },
      title: 'Object id',
      thumbnailUrl: 'https://example.com/object-id.jpg',
    },
  ]);

  render(<Photos />);

  expect(await screen.findByRole('alert')).toHaveTextContent(
    'Unable to load photos.',
  );
  expect(screen.queryByText('Object id')).not.toBeInTheDocument();
});

test('renders an error state when a photo thumbnail URL is not HTTPS', async () => {
  mockFetchSuccess([
    {
      id: 1,
      title: 'Insecure thumbnail',
      thumbnailUrl: 'http://example.com/insecure.jpg',
    },
  ]);

  render(<Photos />);

  expect(await screen.findByRole('alert')).toHaveTextContent(
    'Unable to load photos.',
  );
  expect(screen.queryByText('Insecure thumbnail')).not.toBeInTheDocument();
});

test('renders an error state when a photo thumbnail URL includes credentials', async () => {
  mockFetchSuccess([
    {
      id: 1,
      title: 'Credentialed thumbnail',
      thumbnailUrl: 'https://user:pass@example.com/credentialed.jpg',
    },
  ]);

  render(<Photos />);

  expect(await screen.findByRole('alert')).toHaveTextContent(
    'Unable to load photos.',
  );
  expect(screen.queryByText('Credentialed thumbnail')).not.toBeInTheDocument();
});

test('trims photo titles and normalizes thumbnail URLs before rendering', async () => {
  mockFetchSuccess([
    {
      id: 1,
      title: '  Trimmed photo  ',
      thumbnailUrl: ' https://example.com/trimmed.jpg ',
    },
  ]);

  render(<Photos />);

  expect(
    await screen.findByRole('heading', { name: 'Trimmed photo' }),
  ).toBeInTheDocument();
  expect(screen.getByAltText('Trimmed photo')).toHaveAttribute(
    'src',
    'https://example.com/trimmed.jpg',
  );
  expect(screen.queryByText('  Trimmed photo  ')).not.toBeInTheDocument();
});

test('renders an error state when a malformed photo is beyond the render limit', async () => {
  const manyPhotos = Array.from({ length: MAX_PHOTOS + 1 }, (_, index) => ({
    id: index + 1,
    title: `Photo ${index + 1}`,
    thumbnailUrl: `https://example.com/${index + 1}.jpg`,
  }));
  delete manyPhotos[MAX_PHOTOS].thumbnailUrl;
  mockFetchSuccess(manyPhotos);

  render(<Photos />);

  expect(await screen.findByRole('alert')).toHaveTextContent(
    'Unable to load photos.',
  );
  expect(screen.queryByText('Photo 1')).not.toBeInTheDocument();
});

test('limits rendered photos from large API responses', async () => {
  const manyPhotos = Array.from({ length: MAX_PHOTOS + 1 }, (_, index) => ({
    id: index + 1,
    title: `Photo ${index + 1}`,
    thumbnailUrl: `https://example.com/${index + 1}.jpg`,
  }));
  mockFetchSuccess(manyPhotos);

  render(<Photos />);

  expect(await screen.findByText('Photo 1')).toBeInTheDocument();
  expect(screen.getByText(`Photo ${MAX_PHOTOS}`)).toBeInTheDocument();
  expect(screen.queryByText(`Photo ${MAX_PHOTOS + 1}`)).not.toBeInTheDocument();
});
