import React from 'react';

export const PHOTO_ENDPOINT = 'https://jsonplaceholder.typicode.com/photos';
export const MAX_PHOTOS = 12;

function hasText(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function normalizeHttpsUrl(value) {
  if (!hasText(value)) {
    return null;
  }

  try {
    const url = new URL(value);
    if (url.protocol !== 'https:') {
      return null;
    }

    return url.href;
  } catch (error) {
    return null;
  }
}

function isHttpsUrl(value) {
  return normalizeHttpsUrl(value) !== null;
}

export function isRenderablePhoto(photo) {
  return (
    Boolean(photo) &&
    typeof photo === 'object' &&
    photo.id !== null &&
    photo.id !== undefined &&
    hasText(photo.title) &&
    isHttpsUrl(photo.thumbnailUrl)
  );
}

function normalizePhoto(photo) {
  return {
    ...photo,
    title: photo.title.trim(),
    thumbnailUrl: normalizeHttpsUrl(photo.thumbnailUrl),
  };
}

function hasUniquePhotoIds(photos) {
  const seenIds = new Set();

  return photos.every((photo) => {
    const key = String(photo.id);
    if (seenIds.has(key)) {
      return false;
    }

    seenIds.add(key);
    return true;
  });
}

export function normalizePhotos(photos) {
  if (!Array.isArray(photos)) {
    throw new Error('Photo response must be an array.');
  }

  if (!photos.every(isRenderablePhoto)) {
    throw new Error('Photo records must include id, title, and thumbnailUrl.');
  }

  if (!hasUniquePhotoIds(photos)) {
    throw new Error('Photo records must have unique ids.');
  }

  return photos.map(normalizePhoto).slice(0, MAX_PHOTOS);
}

class Photos extends React.Component {
  state = {
    photos: [],
    loading: true,
    error: null,
  };

  componentDidMount() {
    this.loadPhotos();
  }

  async loadPhotos() {
    try {
      const response = await fetch(PHOTO_ENDPOINT);
      if (!response.ok) {
        throw new Error(`Photo request failed with ${response.status}`);
      }

      const photos = normalizePhotos(await response.json());
      this.setState({ photos, loading: false, error: null });
    } catch (error) {
      this.setState({
        photos: [],
        loading: false,
        error: 'Unable to load photos.',
      });
    }
  }

  render() {
    const { photos, loading, error } = this.state;

    return (
      <section className="photos">
        <h1>Photo List</h1>
        {loading && <p role="status">Loading photos...</p>}
        {error && <p role="alert">{error}</p>}
        <div className="photo-grid">
          {photos.map((photo) => (
            <article className="card" key={photo.id}>
              <div className="card-body">
                <h2 className="card-title">{photo.title}</h2>
                <img src={photo.thumbnailUrl} alt={photo.title} />
              </div>
            </article>
          ))}
        </div>
      </section>
    );
  }
}

export default Photos;
