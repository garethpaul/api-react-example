import { act, render, screen, waitFor } from '@testing-library/react';
import { vi } from 'vitest';
import App from './App';
import Photos, {
  MAX_PHOTOS,
  PHOTO_ENDPOINT,
  PHOTO_REQUEST_TIMEOUT_MS,
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

function mockFetchSuccess(data = photos) {
  global.fetch = vi.fn().mockResolvedValue({
    ok: true,
    json: vi.fn().mockResolvedValue(data),
  });
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

test('does not update state after unmounting during photo load', async () => {
  let resolveJson;
  const json = vi.fn(
    () =>
      new Promise((resolve) => {
        resolveJson = resolve;
      }),
  );
  global.fetch = vi.fn().mockResolvedValue({
    ok: true,
    json,
  });
  const setStateSpy = vi.spyOn(Photos.prototype, 'setState');

  const { unmount } = render(<Photos />);

  await waitFor(() => expect(json).toHaveBeenCalled());
  unmount();

  await act(async () => {
    resolveJson(photos);
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
    json: vi.fn(() => new Promise(() => {})),
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
