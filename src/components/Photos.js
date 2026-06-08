import React from 'react';

export const PHOTO_ENDPOINT = 'https://jsonplaceholder.typicode.com/photos';
export const MAX_PHOTOS = 12;

export function normalizePhotos(photos) {
  if (!Array.isArray(photos)) {
    throw new Error('Photo response must be an array.');
  }

  return photos.slice(0, MAX_PHOTOS);
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
