import React from 'react';

export const PHOTO_ENDPOINT = 'https://jsonplaceholder.typicode.com/photos';
export const MAX_PHOTOS = 12;
export const PHOTO_REQUEST_TIMEOUT_MS = 10000;

function hasText(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function isPhotoId(value) {
  return (
    (typeof value === 'number' && Number.isFinite(value)) || hasText(value)
  );
}

function normalizePhotoId(value) {
  return String(value).trim();
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

    if (url.username || url.password) {
      return null;
    }

    return url.href;
  } catch {
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
    isPhotoId(photo.id) &&
    hasText(photo.title) &&
    isHttpsUrl(photo.thumbnailUrl)
  );
}

function normalizePhoto(photo) {
  return {
    ...photo,
    id: normalizePhotoId(photo.id),
    title: photo.title.trim(),
    thumbnailUrl: normalizeHttpsUrl(photo.thumbnailUrl),
  };
}

function hasUniquePhotoIds(photos) {
  const seenIds = new Set();

  return photos.every((photo) => {
    const key = normalizePhotoId(photo.id);
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

  isActive = false;
  abortController = null;
  requestTimeoutId = null;

  componentDidMount() {
    this.isActive = true;
    this.loadPhotos();
  }

  componentWillUnmount() {
    this.isActive = false;
    this.clearPhotoRequestTimeout();
    if (this.abortController) {
      this.abortController.abort();
      this.abortController = null;
    }
  }

  setPhotosState(nextState) {
    if (this.isActive) {
      this.setState(nextState);
    }
  }

  createPhotoRequestOptions() {
    if (typeof AbortController === 'undefined') {
      return null;
    }

    this.abortController = new AbortController();
    return { signal: this.abortController.signal };
  }

  createPhotoRequestTimeout() {
    return new Promise((_, reject) => {
      this.requestTimeoutId = setTimeout(() => {
        this.requestTimeoutId = null;
        if (this.abortController) {
          this.abortController.abort();
        }
        reject(new Error('Photo request timed out.'));
      }, PHOTO_REQUEST_TIMEOUT_MS);
    });
  }

  clearPhotoRequestTimeout() {
    if (this.requestTimeoutId !== null) {
      clearTimeout(this.requestTimeoutId);
      this.requestTimeoutId = null;
    }
  }

  async fetchPhotos(requestOptions) {
    const response = requestOptions
      ? await fetch(PHOTO_ENDPOINT, requestOptions)
      : await fetch(PHOTO_ENDPOINT);
    if (!response.ok) {
      throw new Error(`Photo request failed with ${response.status}`);
    }

    return normalizePhotos(await response.json());
  }

  async loadPhotos() {
    try {
      const requestOptions = this.createPhotoRequestOptions();
      const photoRequest = this.fetchPhotos(requestOptions);
      const photos = await Promise.race([
        photoRequest,
        this.createPhotoRequestTimeout(),
      ]);
      this.setPhotosState({ photos, loading: false, error: null });
    } catch {
      this.setPhotosState({
        photos: [],
        loading: false,
        error: 'Unable to load photos.',
      });
    } finally {
      this.clearPhotoRequestTimeout();
      this.abortController = null;
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
