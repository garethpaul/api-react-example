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
  const { response } = streamingJsonResponse([bytes], String(bytes.byteLength));
  global.fetch = vi.fn().mockResolvedValue({
    ...response,
    ok: true,
    redirected: false,
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
      expect.objectContaining({
        redirect: 'error',
        signal: expect.any(Object),
      }),
    );
  } else {
    expect(global.fetch).toHaveBeenCalledWith(PHOTO_ENDPOINT, {
      redirect: 'error',
    });
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
  const cancel = vi.fn().mockRejectedValue(new Error('cancel failed'));
  global.fetch = vi.fn().mockResolvedValue({
    ok: false,
    status: 500,
    body: { cancel },
  });

  render(<Photos />);

  expect(await screen.findByRole('alert')).toHaveTextContent(
    'Unable to load photos.',
  );
  expect(cancel).toHaveBeenCalledOnce();
});

test('disables redirects when abort support is unavailable', async () => {
  global.AbortController = undefined;
  mockFetchSuccess();

  render(<Photos />);

  expect(await screen.findByText('First photo')).toBeInTheDocument();
  expect(global.fetch).toHaveBeenCalledWith(PHOTO_ENDPOINT, {
    redirect: 'error',
  });
});

test('rejects a redirected photo response before reading headers or body', async () => {
  const getHeader = vi.fn();
  const arrayBuffer = vi.fn();
  const cancel = vi.fn().mockResolvedValue(undefined);
  global.fetch = vi.fn().mockResolvedValue({
    ok: true,
    redirected: true,
    headers: { get: getHeader },
    body: { cancel },
    arrayBuffer,
  });

  render(<Photos />);

  expect(await screen.findByRole('alert')).toHaveTextContent(
    'Unable to load photos.',
  );
  expect(getHeader).not.toHaveBeenCalled();
  expect(cancel).toHaveBeenCalledOnce();
  expect(arrayBuffer).not.toHaveBeenCalled();
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
  const cancel = vi.fn().mockResolvedValue(undefined);
  global.fetch = vi.fn().mockResolvedValue({
    ok: true,
    headers: jsonHeaders('text/html; charset=utf-8'),
    body: { cancel },
    arrayBuffer,
  });

  render(<Photos />);

  expect(await screen.findByRole('alert')).toHaveTextContent(
    'Unable to load photos.',
  );
  expect(cancel).toHaveBeenCalledOnce();
  expect(arrayBuffer).not.toHaveBeenCalled();
});

test('rejects a declared oversized photo response before reading', async () => {
  const arrayBuffer = vi.fn();
  const cancel = vi.fn().mockRejectedValue(new Error('cancel failed'));
  const response = {
    headers: jsonHeaders(
      'application/json',
      String(MAX_PHOTO_RESPONSE_BYTES + 1),
    ),
    body: { cancel },
    arrayBuffer,
  };

  await expect(readBoundedPhotoJson(response)).rejects.toThrow(
    'Photo response body is too large.',
  );
  expect(cancel).toHaveBeenCalledOnce();
  expect(arrayBuffer).not.toHaveBeenCalled();
});

test('cancels a photo response with a nonnumeric content length', async () => {
  const cancel = vi.fn().mockRejectedValue(new Error('cancel failed'));
  const response = {
    headers: jsonHeaders('application/json', 'not-a-number'),
    body: { cancel },
  };

  await expect(readBoundedPhotoJson(response)).rejects.toThrow(
    'Photo response Content-Length must be numeric.',
  );
  expect(cancel).toHaveBeenCalledOnce();
});

test('cancels a photo response with an unsafe content length', async () => {
  const cancel = vi.fn().mockResolvedValue(undefined);
  const response = {
    headers: jsonHeaders('application/json', '9007199254740992'),
    body: { cancel },
  };

  await expect(readBoundedPhotoJson(response)).rejects.toThrow(
    'Photo response Content-Length is outside the safe range.',
  );
  expect(cancel).toHaveBeenCalledOnce();
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

test('parses a valid photo response split into one-byte stream chunks', async () => {
  const json = JSON.stringify(photos);
  const chunks = Array.from(utf8.encode(json), (byte) => Uint8Array.of(byte));
  const { response, reader } = streamingJsonResponse(chunks);

  await expect(readBoundedPhotoJson(response)).resolves.toEqual(photos);
  expect(reader.read).toHaveBeenCalledTimes(chunks.length + 1);
  expect(reader.cancel).not.toHaveBeenCalled();
  expect(reader.releaseLock).toHaveBeenCalledTimes(1);
});

test('rejects a non-byte photo stream chunk and clears reader ownership', async () => {
  const spoofedChunk = {
    byteLength: 1,
    [Symbol.toStringTag]: 'Uint8Array',
  };
  const { response, reader } = streamingJsonResponse([spoofedChunk]);
  const setReaderCancel = vi.fn();

  await expect(readBoundedPhotoJson(response, setReaderCancel)).rejects.toThrow(
    'Photo response stream chunk is invalid.',
  );
  expect(reader.cancel).toHaveBeenCalledTimes(1);
  expect(reader.releaseLock).toHaveBeenCalledTimes(1);
  expect(setReaderCancel).toHaveBeenCalledWith(expect.any(Function));
  expect(setReaderCancel).toHaveBeenLastCalledWith(null);
});

test('rejects an empty photo stream chunk without waiting for timeout', async () => {
  const { response, reader } = streamingJsonResponse([new Uint8Array(0)]);

  await expect(readBoundedPhotoJson(response)).rejects.toThrow(
    'Photo response stream chunk is invalid.',
  );
  expect(reader.cancel).toHaveBeenCalledTimes(1);
  expect(reader.read).toHaveBeenCalledTimes(1);
  expect(reader.releaseLock).toHaveBeenCalledTimes(1);
});

test('preserves the invalid chunk error when reader cancellation fails', async () => {
  const { response, reader } = streamingJsonResponse([new Uint8Array(0)]);
  reader.cancel.mockRejectedValue(new Error('cancel failed'));

  await expect(readBoundedPhotoJson(response)).rejects.toThrow(
    'Photo response stream chunk is invalid.',
  );
  expect(reader.cancel).toHaveBeenCalledTimes(1);
  expect(reader.releaseLock).toHaveBeenCalledTimes(1);
});

test('rejects an unstreamable photo response without whole-body fallback', async () => {
  const arrayBuffer = vi.fn();
  const cancel = vi.fn().mockResolvedValue(undefined);
  const response = {
    headers: jsonHeaders('application/json', String(MAX_PHOTO_RESPONSE_BYTES)),
    body: { cancel },
    arrayBuffer,
  };

  await expect(readBoundedPhotoJson(response)).rejects.toThrow(
    'Photo response body must be a readable stream.',
  );
  expect(cancel).toHaveBeenCalledOnce();
  expect(arrayBuffer).not.toHaveBeenCalled();
});

test('rejects malformed UTF-8 photo response bytes', async () => {
  const { response } = streamingJsonResponse([new Uint8Array([0x80])], '1');

  await expect(readBoundedPhotoJson(response)).rejects.toThrow(TypeError);
});

test('accepts valid JSON exactly at the photo response byte limit', async () => {
  const json = `${' '.repeat(MAX_PHOTO_RESPONSE_BYTES - 2)}[]`;
  const bytes = utf8.encode(json);
  const { response } = streamingJsonResponse([bytes], String(bytes.byteLength));

  expect(bytes.byteLength).toBe(MAX_PHOTO_RESPONSE_BYTES);
  await expect(readBoundedPhotoJson(response)).resolves.toEqual([]);
});

test('does not update state after unmounting during photo load', async () => {
  let finishRead;
  const read = vi.fn(
    () =>
      new Promise((resolve) => {
        finishRead = resolve;
      }),
  );
  const cancel = vi.fn().mockImplementation(() => {
    finishRead({ done: true, value: undefined });
    return Promise.resolve();
  });
  global.fetch = vi.fn().mockResolvedValue({
    ok: true,
    headers: jsonHeaders('application/json'),
    body: {
      getReader: vi.fn(() => ({ read, cancel, releaseLock: vi.fn() })),
    },
  });
  const setStateSpy = vi.spyOn(Photos.prototype, 'setState');

  const { unmount } = render(<Photos />);

  await waitFor(() => expect(read).toHaveBeenCalled());
  unmount();

  await act(async () => {
    await Promise.resolve();
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

  expect(global.fetch).toHaveBeenCalledWith(PHOTO_ENDPOINT, {
    redirect: 'error',
    signal,
  });

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
      ...streamingJsonResponse([utf8.encode(JSON.stringify(photos))]).response,
      ok: true,
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

test('cancels a photo response that resolves after timeout without abort support', async () => {
  vi.useFakeTimers();
  global.AbortController = undefined;
  let resolveFetch;
  const cancel = vi.fn().mockResolvedValue(undefined);
  const getReader = vi.fn();
  const headers = { get: vi.fn() };
  const readOk = vi.fn(() => true);
  const readRedirected = vi.fn(() => false);
  const response = { body: { cancel, getReader }, headers };
  Object.defineProperty(response, 'ok', { get: readOk });
  Object.defineProperty(response, 'redirected', { get: readRedirected });
  global.fetch = vi.fn(
    () =>
      new Promise((resolve) => {
        resolveFetch = resolve;
      }),
  );

  render(<Photos />);

  await act(async () => {
    await vi.advanceTimersByTimeAsync(PHOTO_REQUEST_TIMEOUT_MS);
  });
  expect(screen.getByRole('alert')).toHaveTextContent('Unable to load photos.');

  await act(async () => {
    resolveFetch(response);
    await Promise.resolve();
  });

  expect(cancel).toHaveBeenCalledTimes(1);
  expect(readOk).not.toHaveBeenCalled();
  expect(readRedirected).not.toHaveBeenCalled();
  expect(headers.get).not.toHaveBeenCalled();
  expect(getReader).not.toHaveBeenCalled();
});

test('rejects an unstreamable response without abort support', async () => {
  global.AbortController = undefined;
  const arrayBuffer = vi.fn();
  global.fetch = vi.fn().mockResolvedValue({
    ok: true,
    headers: jsonHeaders('application/json', '2'),
    arrayBuffer,
  });

  render(<Photos />);

  expect(await screen.findByRole('alert')).toHaveTextContent(
    'Unable to load photos.',
  );
  expect(arrayBuffer).not.toHaveBeenCalled();
});

test('cancels a pending photo stream on timeout without abort support', async () => {
  vi.useFakeTimers();
  global.AbortController = undefined;
  let finishRead;
  const read = vi.fn(
    () =>
      new Promise((resolve) => {
        finishRead = resolve;
      }),
  );
  const cancel = vi.fn().mockImplementation(() => {
    finishRead({ done: true });
    return Promise.resolve();
  });
  const releaseLock = vi.fn();
  global.fetch = vi.fn().mockResolvedValue({
    ok: true,
    headers: jsonHeaders('application/json'),
    body: {
      getReader: vi.fn(() => ({ read, cancel, releaseLock })),
    },
  });

  render(<Photos />);
  await act(async () => {
    await Promise.resolve();
    await Promise.resolve();
  });
  expect(read).toHaveBeenCalledTimes(1);

  await act(async () => {
    await vi.advanceTimersByTimeAsync(PHOTO_REQUEST_TIMEOUT_MS);
  });

  expect(cancel).toHaveBeenCalledTimes(1);
  expect(releaseLock).toHaveBeenCalledTimes(1);
  expect(screen.getByRole('alert')).toHaveTextContent('Unable to load photos.');
});

test('cancels a pending photo stream on unmount without abort support', async () => {
  global.AbortController = undefined;
  let finishRead;
  const read = vi.fn(
    () =>
      new Promise((resolve) => {
        finishRead = resolve;
      }),
  );
  const cancel = vi.fn().mockImplementation(() => {
    finishRead({ done: true });
    return Promise.resolve();
  });
  const releaseLock = vi.fn();
  global.fetch = vi.fn().mockResolvedValue({
    ok: true,
    headers: jsonHeaders('application/json'),
    body: {
      getReader: vi.fn(() => ({ read, cancel, releaseLock })),
    },
  });

  const { unmount } = render(<Photos />);
  await act(async () => {
    await Promise.resolve();
    await Promise.resolve();
  });
  expect(read).toHaveBeenCalledTimes(1);

  unmount();
  await act(async () => {
    await Promise.resolve();
  });

  expect(cancel).toHaveBeenCalledTimes(1);
  expect(releaseLock).toHaveBeenCalledTimes(1);
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

test.each([
  'https://example.com:1/thumbnail.jpg',
  'https://example.com:80/thumbnail.jpg',
  'https://example.com:444/thumbnail.jpg',
  'https://example.com:8443/thumbnail.jpg',
  'https://example.com:65535/thumbnail.jpg',
])('rejects a nondefault thumbnail HTTPS port: %s', async (thumbnailUrl) => {
  mockFetchSuccess([
    {
      id: 1,
      title: 'Alternate port thumbnail',
      thumbnailUrl,
    },
  ]);

  render(<Photos />);

  expect(await screen.findByRole('alert')).toHaveTextContent(
    'Unable to load photos.',
  );
  expect(screen.queryByRole('img')).not.toBeInTheDocument();
});

test.each([
  ['https://example.com/thumbnail.jpg', 'https://example.com/thumbnail.jpg'],
  [
    'https://example.com:443/thumbnail.jpg',
    'https://example.com/thumbnail.jpg',
  ],
])(
  'preserves the default thumbnail HTTPS port: %s',
  async (thumbnailUrl, normalizedUrl) => {
    mockFetchSuccess([
      {
        id: 1,
        title: 'Default port thumbnail',
        thumbnailUrl,
      },
    ]);

    render(<Photos />);

    expect(
      await screen.findByAltText('Default port thumbnail'),
    ).toHaveAttribute('src', normalizedUrl);
  },
);

test.each([
  'https://localhost/thumbnail.jpg',
  'https://LOCALHOST./thumbnail.jpg',
  'https://images.localhost/thumbnail.jpg',
  'https://127.1/thumbnail.jpg',
  'https://2130706433/thumbnail.jpg',
  'https://0177.0.0.1/thumbnail.jpg',
  'https://0x7f000001/thumbnail.jpg',
  'https://0.0.0.0/thumbnail.jpg',
  'https://10.1/thumbnail.jpg',
  'https://10.255.255.255/thumbnail.jpg',
  'https://167772161/thumbnail.jpg',
  'https://100.64.0.0/thumbnail.jpg',
  'https://100.127.255.255/thumbnail.jpg',
  'https://1681915905/thumbnail.jpg',
  'https://127.255.255.255/thumbnail.jpg',
  'https://169.254.1.1/thumbnail.jpg',
  'https://169.254.255.255/thumbnail.jpg',
  'https://172.16.0.1/thumbnail.jpg',
  'https://172.31.255.255/thumbnail.jpg',
  'https://192.168.1.1/thumbnail.jpg',
  'https://192.168.255.255/thumbnail.jpg',
  'https://[::]/thumbnail.jpg',
  'https://[::1]/thumbnail.jpg',
  'https://[fc00::1]/thumbnail.jpg',
  'https://[fdff:ffff::1]/thumbnail.jpg',
  'https://[fe80::1]/thumbnail.jpg',
  'https://[febf:ffff::1]/thumbnail.jpg',
  'https://[::ffff:10.0.0.1]/thumbnail.jpg',
  'https://[::ffff:6440:1]/thumbnail.jpg',
])(
  'rejects a local thumbnail address literal before rendering: %s',
  async (thumbnailUrl) => {
    mockFetchSuccess([
      {
        id: 1,
        title: 'Local thumbnail',
        thumbnailUrl,
      },
    ]);

    render(<Photos />);

    expect(await screen.findByRole('alert')).toHaveTextContent(
      'Unable to load photos.',
    );
    expect(screen.queryByRole('img')).not.toBeInTheDocument();
  },
);

test.each([
  'https://224.0.0.0/thumbnail.jpg',
  'https://239.255.255.255/thumbnail.jpg',
  'https://240.0.0.0/thumbnail.jpg',
  'https://255.255.255.255/thumbnail.jpg',
  'https://[ff00::]/thumbnail.jpg',
  'https://[ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff]/thumbnail.jpg',
])(
  'rejects a non-unicast thumbnail address literal before rendering: %s',
  async (thumbnailUrl) => {
    mockFetchSuccess([
      {
        id: 1,
        title: 'Non-unicast thumbnail',
        thumbnailUrl,
      },
    ]);

    render(<Photos />);

    expect(await screen.findByRole('alert')).toHaveTextContent(
      'Unable to load photos.',
    );
    expect(screen.queryByRole('img')).not.toBeInTheDocument();
  },
);

test.each([
  'https://[64:ff9b:1::1]/thumbnail.jpg',
  'https://[64:ff9b:1:ffff:ffff:ffff:ffff:ffff]/thumbnail.jpg',
  'https://[100::1]/thumbnail.jpg',
  'https://[100::ffff:ffff:ffff:ffff]/thumbnail.jpg',
  'https://[100:0:0:1::1]/thumbnail.jpg',
  'https://[100:0:0:1:ffff:ffff:ffff:ffff]/thumbnail.jpg',
  'https://[2001:2::1]/thumbnail.jpg',
  'https://[2001:2:0:ffff:ffff:ffff:ffff:ffff]/thumbnail.jpg',
  'https://[2001:db8::1]/thumbnail.jpg',
  'https://[2001:db8:ffff:ffff:ffff:ffff:ffff:ffff]/thumbnail.jpg',
  'https://[3fff::1]/thumbnail.jpg',
  'https://[3fff:fff:ffff:ffff:ffff:ffff:ffff:ffff]/thumbnail.jpg',
  'https://[5f00::1]/thumbnail.jpg',
  'https://[5f00:ffff:ffff:ffff:ffff:ffff:ffff:ffff]/thumbnail.jpg',
  'https://[fec0::1]/thumbnail.jpg',
  'https://[feff:ffff:ffff:ffff:ffff:ffff:ffff:ffff]/thumbnail.jpg',
])(
  'rejects a non-global special-purpose IPv6 thumbnail literal: %s',
  async (thumbnailUrl) => {
    mockFetchSuccess([
      {
        id: 1,
        title: 'Special-purpose thumbnail',
        thumbnailUrl,
      },
    ]);

    render(<Photos />);

    expect(await screen.findByRole('alert')).toHaveTextContent(
      'Unable to load photos.',
    );
    expect(screen.queryByRole('img')).not.toBeInTheDocument();
  },
);

test.each([
  'https://[64:ff9b::808:808]/thumbnail.jpg',
  'https://[64:ff9b:2::1]/thumbnail.jpg',
  'https://[100:0:0:2::1]/thumbnail.jpg',
  'https://[2001:2:1::1]/thumbnail.jpg',
  'https://[2001:db7:ffff::1]/thumbnail.jpg',
  'https://[2001:db9::1]/thumbnail.jpg',
  'https://[3fff:1000::1]/thumbnail.jpg',
  'https://[5eff:ffff::1]/thumbnail.jpg',
  'https://[6000::1]/thumbnail.jpg',
])(
  'preserves an IPv6 literal outside the selected special-purpose prefixes: %s',
  async (thumbnailUrl) => {
    mockFetchSuccess([
      {
        id: 1,
        title: 'Out-of-policy thumbnail',
        thumbnailUrl,
      },
    ]);

    render(<Photos />);

    expect(
      await screen.findByAltText('Out-of-policy thumbnail'),
    ).toHaveAttribute('src', new URL(thumbnailUrl).href);
  },
);

test.each([
  'https://8.8.8.8/thumbnail.jpg',
  'https://11.0.0.1/thumbnail.jpg',
  'https://100.63.255.255/thumbnail.jpg',
  'https://100.128.0.0/thumbnail.jpg',
  'https://169.253.255.255/thumbnail.jpg',
  'https://172.15.255.255/thumbnail.jpg',
  'https://172.32.0.0/thumbnail.jpg',
  'https://192.169.0.1/thumbnail.jpg',
  'https://223.255.255.255/thumbnail.jpg',
  'https://[2001:4860:4860::8888]/thumbnail.jpg',
  'https://[::ffff:8.8.8.8]/thumbnail.jpg',
  'https://images.localhost.example/thumbnail.jpg',
])(
  'preserves a public or DNS-style thumbnail host: %s',
  async (thumbnailUrl) => {
    mockFetchSuccess([
      {
        id: 1,
        title: 'Public thumbnail',
        thumbnailUrl,
      },
    ]);

    render(<Photos />);

    expect(await screen.findByAltText('Public thumbnail')).toHaveAttribute(
      'src',
      new URL(thumbnailUrl).href,
    );
  },
);

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
