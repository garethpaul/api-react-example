import React from 'react';

class Photos extends React.Component {
    constructor(){
        super();
        this.state = {
            photos: [],
        }
    }

    componentWillMount() {
        fetch('http://jsonplaceholder.typicode.com/photos')
        .then(res => res.json())
        .then((data) => {
          this.setState({ photos: data })
        })
    .catch(console.log)
    }

    render() {
      return (
        <div>
            <center><h1>Photo List</h1></center>
            {this.state.photos.map((photo) => (
            <div class="card">
                <div class="card-body">
                <h5 class="card-title">{photo.title}</h5>
                <img src={photo.thumbnailUrl} alt={photo.title} />
                </div>
            </div>
            ))}
      </div>
      );
    }
  }

export default Photos;