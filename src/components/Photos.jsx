import React from 'react';

export const PHOTO_ENDPOINT = 'https://jsonplaceholder.typicode.com/photos';
export const MAX_PHOTOS = 12;
export const PHOTO_REQUEST_TIMEOUT_MS = 10000;
export const MAX_PHOTO_RESPONSE_BYTES = 2 * 1024 * 1024;

const BLOCKED_SPECIAL_IPV6_PREFIXES = [
  '64:ff9b:1::/48',
  '100::/64',
  '100:0:0:1::/64',
  '2001:2::/48',
  '2001:db8::/32',
  '3fff::/20',
  '5f00::/16',
  'fec0::/10',
].map((cidr) => {
  const [address, prefixLength] = cidr.split('/');
  return {
    address: parseIpv6Hextets(address),
    prefixLength: Number(prefixLength),
  };
});
const VISIBLE_TITLE_CHARACTER =
  /[\p{Letter}\p{Number}\p{Punctuation}\p{Symbol}]/u;

function hasText(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function hasVisibleTitle(value) {
  return typeof value === 'string' && VISIBLE_TITLE_CHARACTER.test(value);
}

function isPhotoId(value) {
  return (
    (typeof value === 'number' && Number.isFinite(value)) || hasText(value)
  );
}

function normalizePhotoId(value) {
  return String(value).trim();
}

function parseIpv4Hostname(hostname) {
  const parts = hostname.split('.');
  if (
    parts.length !== 4 ||
    parts.some((part) => !/^\d+$/.test(part) || Number(part) > 255)
  ) {
    return null;
  }

  return parts.reduce((address, part) => address * 256 + Number(part), 0);
}

function isBlockedIpv4Address(address) {
  return (
    address <= 0x00ffffff ||
    (address >= 0x0a000000 && address <= 0x0affffff) ||
    (address >= 0x64400000 && address <= 0x647fffff) ||
    (address >= 0x7f000000 && address <= 0x7fffffff) ||
    (address >= 0xa9fe0000 && address <= 0xa9feffff) ||
    (address >= 0xac100000 && address <= 0xac1fffff) ||
    (address >= 0xc0a80000 && address <= 0xc0a8ffff) ||
    (address >= 0xe0000000 && address <= 0xefffffff) ||
    (address >= 0xf0000000 && address <= 0xffffffff)
  );
}

function ipv4MappedAddress(ipv6Address) {
  if (!ipv6Address.startsWith('::ffff:')) {
    return null;
  }

  const parts = ipv6Address.slice('::ffff:'.length).split(':');
  if (parts.length !== 2) {
    return null;
  }

  const high = Number.parseInt(parts[0], 16);
  const low = Number.parseInt(parts[1], 16);
  if (
    !Number.isInteger(high) ||
    high < 0 ||
    high > 0xffff ||
    !Number.isInteger(low) ||
    low < 0 ||
    low > 0xffff
  ) {
    return null;
  }

  return high * 0x10000 + low;
}

function wellKnownNat64MappedAddress(hextets) {
  const isWellKnownNat64 =
    hextets[0] === 0x0064 &&
    hextets[1] === 0xff9b &&
    hextets.slice(2, 6).every((hextet) => hextet === 0);

  if (!isWellKnownNat64) {
    return null;
  }

  return hextets[6] * 0x10000 + hextets[7];
}

function parseIpv6Hextets(address) {
  const compressedParts = address.split('::');
  if (compressedParts.length > 2) {
    return null;
  }

  const parseParts = (value) => {
    if (value === '') {
      return [];
    }

    const parts = value.split(':');
    if (parts.some((part) => !/^[0-9a-f]{1,4}$/i.test(part))) {
      return null;
    }
    return parts.map((part) => Number.parseInt(part, 16));
  };

  const left = parseParts(compressedParts[0]);
  const right = parseParts(compressedParts[1] ?? '');
  if (left === null || right === null) {
    return null;
  }

  if (compressedParts.length === 1) {
    return left.length === 8 ? left : null;
  }

  const omittedHextets = 8 - left.length - right.length;
  if (omittedHextets < 1) {
    return null;
  }

  return [...left, ...new Array(omittedHextets).fill(0), ...right];
}

function matchesIpv6Prefix(address, prefix) {
  if (address === null || prefix.address === null) {
    return false;
  }

  const completeHextets = Math.floor(prefix.prefixLength / 16);
  for (let index = 0; index < completeHextets; index += 1) {
    if (address[index] !== prefix.address[index]) {
      return false;
    }
  }

  const remainingBits = prefix.prefixLength % 16;
  if (remainingBits === 0) {
    return true;
  }

  const mask = (0xffff << (16 - remainingBits)) & 0xffff;
  return (
    (address[completeHextets] & mask) ===
    (prefix.address[completeHextets] & mask)
  );
}

function isBlockedIpv6Address(hostname) {
  if (!hostname.startsWith('[') || !hostname.endsWith(']')) {
    return false;
  }

  const address = hostname.slice(1, -1);
  if (address === '::' || address === '::1') {
    return true;
  }

  const mappedAddress = ipv4MappedAddress(address);
  if (mappedAddress !== null) {
    return isBlockedIpv4Address(mappedAddress);
  }

  const hextets = parseIpv6Hextets(address);
  if (hextets === null) {
    return true;
  }

  const nat64MappedAddress = wellKnownNat64MappedAddress(hextets);
  if (nat64MappedAddress !== null && isBlockedIpv4Address(nat64MappedAddress)) {
    return true;
  }

  if (
    BLOCKED_SPECIAL_IPV6_PREFIXES.some((prefix) =>
      matchesIpv6Prefix(hextets, prefix),
    )
  ) {
    return true;
  }

  const firstHextet = hextets[0];
  return (
    (firstHextet >= 0xfc00 && firstHextet <= 0xfdff) ||
    (firstHextet >= 0xfe80 && firstHextet <= 0xfebf) ||
    (firstHextet >= 0xff00 && firstHextet <= 0xffff)
  );
}

function isBlockedThumbnailHost(hostname) {
  let normalizedHostname = hostname.toLowerCase();
  if (normalizedHostname.endsWith('.')) {
    normalizedHostname = normalizedHostname.slice(0, -1);
  }

  if (
    normalizedHostname === 'localhost' ||
    normalizedHostname.endsWith('.localhost')
  ) {
    return true;
  }

  const ipv4Address = parseIpv4Hostname(normalizedHostname);
  return (
    (ipv4Address !== null && isBlockedIpv4Address(ipv4Address)) ||
    isBlockedIpv6Address(normalizedHostname)
  );
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

    if (url.port !== '') {
      return null;
    }

    if (isBlockedThumbnailHost(url.hostname)) {
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
  const contentLengthHeader = response.headers?.get('content-length');
  let contentLength;
  try {
    contentLength = parseContentLength(contentLengthHeader);
  } catch (error) {
    cancelUnreadPhotoResponse(response);
    throw error;
  }
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
    hasVisibleTitle(photo.title) &&
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
    if (this.activeRequest !== request) {
      cancelUnreadPhotoResponse(response);
      throw new Error('Photo response arrived after request ownership ended.');
    }

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
