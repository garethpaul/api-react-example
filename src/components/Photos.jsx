import React from 'react';

export const PHOTO_ENDPOINT = 'https://jsonplaceholder.typicode.com/photos';
export const MAX_PHOTOS = 12;
export const PHOTO_REQUEST_TIMEOUT_MS = 10000;
export const MAX_PHOTO_RESPONSE_BYTES = 2 * 1024 * 1024;

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

export function isJsonContentType(value) {
  if (typeof value !== 'string') {
    return false;
  }

  const mediaType = value.split(';', 1)[0].trim().toLowerCase();
  return (
    mediaType === 'application/json' ||
    /^application\/[!#$%&'*+.^_`|~0-9a-z-]+\+json$/.test(mediaType)
  );
}

function parseContentLength(value) {
  if (value === null || value === undefined) {
    return null;
  }

  const normalizedValue = String(value).trim();
  if (!/^\d+$/.test(normalizedValue)) {
    throw new Error('Photo response Content-Length must be numeric.');
  }

  const length = Number(normalizedValue);
  if (!Number.isSafeInteger(length)) {
    throw new Error('Photo response Content-Length is outside the safe range.');
  }
  return length;
}

function parsePhotoJsonBytes(bytes) {
  if (bytes.byteLength > MAX_PHOTO_RESPONSE_BYTES) {
    throw new Error('Photo response body is too large.');
  }

  const text = new TextDecoder('utf-8', { fatal: true }).decode(bytes);
  return JSON.parse(text);
}

function isUint8Array(value) {
  return (
    ArrayBuffer.isView(value) &&
    Object.prototype.toString.call(value) === '[object Uint8Array]'
  );
}

async function cancelPhotoReader(reader) {
  try {
    await reader.cancel();
  } catch {
    // Preserve the deterministic validation error if cancellation also fails.
  }
}

function cancelUnreadPhotoResponse(response) {
  const body = response?.body;
  if (typeof body?.cancel !== 'function') {
    return;
  }

  try {
    Promise.resolve(body.cancel()).catch(() => {});
  } catch {
    // Preserve the response validation error if transport cleanup also fails.
  }
}

async function readPhotoStream(body, setReaderCancel) {
  const reader = body.getReader();
  const bytes = new Uint8Array(MAX_PHOTO_RESPONSE_BYTES);
  let receivedBytes = 0;
  const cancelReader = () => reader.cancel();

  if (setReaderCancel) {
    setReaderCancel(cancelReader);
  }

  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) {
        break;
      }

      if (!isUint8Array(value) || value.byteLength === 0) {
        await cancelPhotoReader(reader);
        throw new Error('Photo response stream chunk is invalid.');
      }

      const chunk = value;
      if (chunk.byteLength > MAX_PHOTO_RESPONSE_BYTES - receivedBytes) {
        await cancelPhotoReader(reader);
        throw new Error('Photo response body is too large.');
      }
      bytes.set(chunk, receivedBytes);
      receivedBytes += chunk.byteLength;
    }
  } finally {
    if (setReaderCancel) {
      setReaderCancel(null);
    }
    reader.releaseLock();
  }

  return parsePhotoJsonBytes(bytes.subarray(0, receivedBytes));
}

export async function readBoundedPhotoJson(response, setReaderCancel = null) {
  const contentLength = parseContentLength(
    response.headers?.get('content-length'),
  );
  if (contentLength !== null && contentLength > MAX_PHOTO_RESPONSE_BYTES) {
    cancelUnreadPhotoResponse(response);
    throw new Error('Photo response body is too large.');
  }

  if (typeof response.body?.getReader !== 'function') {
    cancelUnreadPhotoResponse(response);
    throw new Error('Photo response body must be a readable stream.');
  }

  return readPhotoStream(response.body, setReaderCancel);
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
      cancelResponseBody: null,
      timeoutId: null,
    };
    this.activeRequest = request;
    return request;
  }

  createPhotoRequestOptions(request) {
    const options = { redirect: 'error' };
    if (request.abortController) {
      options.signal = request.abortController.signal;
    }
    return options;
  }

  createPhotoRequestTimeout(request) {
    return new Promise((_, reject) => {
      request.timeoutId = setTimeout(() => {
        request.timeoutId = null;
        this.cancelPhotoResponseBody(request);
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

  cancelPhotoResponseBody(request) {
    const cancelResponseBody = request.cancelResponseBody;
    request.cancelResponseBody = null;
    if (!cancelResponseBody) {
      return;
    }

    try {
      Promise.resolve(cancelResponseBody()).catch(() => {});
    } catch {
      // Request cancellation remains best effort during timeout and unmount.
    }
  }

  cancelActivePhotoRequest() {
    const request = this.activeRequest;
    if (!request) {
      return;
    }

    this.activeRequest = null;
    this.clearPhotoRequestTimeout(request);
    this.cancelPhotoResponseBody(request);
    if (request.abortController) {
      request.abortController.abort();
    }
  }

  async fetchPhotos(request) {
    const requestOptions = this.createPhotoRequestOptions(request);
    const response = await fetch(PHOTO_ENDPOINT, requestOptions);
    if (!response.ok) {
      cancelUnreadPhotoResponse(response);
      throw new Error(`Photo request failed with ${response.status}`);
    }
    if (response.redirected) {
      cancelUnreadPhotoResponse(response);
      throw new Error('Photo response redirects are not allowed.');
    }

    const contentType = response.headers?.get('content-type');
    if (!isJsonContentType(contentType)) {
      cancelUnreadPhotoResponse(response);
      throw new Error('Photo response must use a JSON content type.');
    }

    return normalizePhotos(
      await readBoundedPhotoJson(response, (cancelResponseBody) => {
        request.cancelResponseBody = cancelResponseBody;
      }),
    );
  }

  async loadPhotos() {
    const request = this.createPhotoRequest();
    try {
      const photoRequest = this.fetchPhotos(request);
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
