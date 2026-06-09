import React from 'react';
import { render, screen } from '@testing-library/react';
import App from './App';
import Photos, { MAX_PHOTOS, PHOTO_ENDPOINT } from './components/Photos';

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

function mockFetchSuccess(data = photos) {
  global.fetch = jest.fn().mockResolvedValue({
    ok: true,
    json: jest.fn().mockResolvedValue(data),
  });
}

afterEach(() => {
  jest.restoreAllMocks();
  delete global.fetch;
});

test('renders the photo list heading from the app shell', async () => {
  mockFetchSuccess();

  render(<App />);

  expect(
    screen.getByRole('heading', { name: /photo list/i })
  ).toBeInTheDocument();
  expect(await screen.findByText('First photo')).toBeInTheDocument();
});

test('loads and renders photos from the placeholder API', async () => {
  mockFetchSuccess();

  render(<Photos />);

  expect(screen.getByRole('status')).toHaveTextContent('Loading photos...');
  expect(global.fetch).toHaveBeenCalledWith(PHOTO_ENDPOINT);
  expect(await screen.findByText('First photo')).toBeInTheDocument();
  expect(screen.getByAltText('Second photo')).toHaveAttribute(
    'src',
    'https://example.com/second.jpg'
  );
});

test('renders an error state when the photo request fails', async () => {
  global.fetch = jest.fn().mockRejectedValue(new Error('network failed'));

  render(<Photos />);

  expect(await screen.findByRole('alert')).toHaveTextContent(
    'Unable to load photos.'
  );
});

test('renders an error state when the photo request is not ok', async () => {
  global.fetch = jest.fn().mockResolvedValue({
    ok: false,
    status: 500,
  });

  render(<Photos />);

  expect(await screen.findByRole('alert')).toHaveTextContent(
    'Unable to load photos.'
  );
});

test('renders an error state when the photo response is not an array', async () => {
  mockFetchSuccess({ unexpected: true });

  render(<Photos />);

  expect(await screen.findByRole('alert')).toHaveTextContent(
    'Unable to load photos.'
  );
});

test('renders an error state when a photo item is missing render fields', async () => {
  mockFetchSuccess([{ id: 1, title: 'Missing thumbnail' }]);

  render(<Photos />);

  expect(await screen.findByRole('alert')).toHaveTextContent(
    'Unable to load photos.'
  );
  expect(screen.queryByText('Missing thumbnail')).not.toBeInTheDocument();
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
    'Unable to load photos.'
  );
  expect(screen.queryByText('Insecure thumbnail')).not.toBeInTheDocument();
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
    'Unable to load photos.'
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
