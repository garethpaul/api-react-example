import React from 'react';
import { render, screen } from '@testing-library/react';
import App from './App';
import Photos, { PHOTO_ENDPOINT } from './components/Photos';

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
