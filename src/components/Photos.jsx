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
  activeRequest = null;

  componentDidMount() {
    this.isActive = true;
    this.loadPhotos();
  }

  componentWillUnmount() {
    this.isActive = false;
    this.cancelActivePhotoRequest();
  }

  setPhotosState(request, nextState) {
    if (this.isActive && this.activeRequest === request) {
      this.setState(nextState);
    }
  }

  createPhotoRequest() {
    this.cancelActivePhotoRequest();
    const request = {
      abortController:
        typeof AbortController === 'undefined' ? null : new AbortController(),
      timeoutId: null,
    };
    this.activeRequest = request;
    return request;
  }

  createPhotoRequestOptions(request) {
    return request.abortController
      ? { signal: request.abortController.signal }
      : null;
  }

  createPhotoRequestTimeout(request) {
    return new Promise((_, reject) => {
      request.timeoutId = setTimeout(() => {
        request.timeoutId = null;
        if (request.abortController) {
          request.abortController.abort();
        }
        reject(new Error('Photo request timed out.'));
      }, PHOTO_REQUEST_TIMEOUT_MS);
    });
  }

  clearPhotoRequestTimeout(request) {
    if (request.timeoutId !== null) {
      clearTimeout(request.timeoutId);
      request.timeoutId = null;
    }
  }

  cancelActivePhotoRequest() {
    const request = this.activeRequest;
    if (!request) {
      return;
    }

    this.activeRequest = null;
    this.clearPhotoRequestTimeout(request);
    if (request.abortController) {
      request.abortController.abort();
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
    const request = this.createPhotoRequest();
    try {
      const requestOptions = this.createPhotoRequestOptions(request);
      const photoRequest = this.fetchPhotos(requestOptions);
      const photos = await Promise.race([
        photoRequest,
        this.createPhotoRequestTimeout(request),
      ]);
      this.setPhotosState(request, { photos, loading: false, error: null });
    } catch {
      this.setPhotosState(request, {
        photos: [],
        loading: false,
        error: 'Unable to load photos.',
      });
    } finally {
      this.clearPhotoRequestTimeout(request);
      if (this.activeRequest === request) {
        this.activeRequest = null;
      }
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
                <img
                  src={photo.thumbnailUrl}
                  alt={photo.title}
                  loading="lazy"
                  referrerPolicy="no-referrer"
                />
              </div>
            </article>
          ))}
        </div>
      </section>
    );
  }
}

export default Photos;
