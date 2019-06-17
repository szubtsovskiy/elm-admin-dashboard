import GoogleMapsLoader from "google-maps";

function findMinMax(acc, lngLat) {
  const lng = lngLat[0];
  const lat = lngLat[1];

  if (lat < acc.minLat) {
    acc.minLat = lat;
  }

  if (lat > acc.maxLat) {
    acc.maxLat = lat;
  }

  if (lng < acc.minLng) {
    acc.minLng = lng
  }

  if (lng > acc.maxLng) {
    acc.maxLng = lng;
  }

  return acc;
}

function createEditors(node) {
  if ( node.tagName && node.tagName.toLowerCase() === 'div' && node.querySelectorAll ) {
    node.querySelectorAll('area-editor').forEach(areaEditor => {
      GoogleMapsLoader.KEY = process.env.GOOGLE_API_KEY;
      GoogleMapsLoader.VERSION = "3.exp";
      GoogleMapsLoader.load(google => {

        const area = JSON.parse(areaEditor.dataset.area);
        let center;
        if (area.type === "Polygon" && area.coordinates.length > 0) {
          let externalRing = area.coordinates[0];
          const acc = externalRing.reduce(findMinMax, {minLat: 90, maxLat: -90, minLng: 90, maxLng: -90});
          center = new google.maps.LatLng((acc.minLat + acc.maxLat) / 2, (acc.minLng + acc.maxLng) / 2);
          console.log(`Map center: (${center.lat()}, ${center.lng()}).`)
        } else {
          center = new google.maps.LatLng(59.3293, 18.0686);
          console.log(`Unsupported area type "${area.type}" or missing coordinates. Setting default center to (${center.lat()}, ${center.lng()}).`);
        }

        const mapOptions = {
          zoom: 11,
          center: center
        };

        const prize = JSON.parse(areaEditor.dataset.prize);
        const map = new google.maps.Map(areaEditor, mapOptions);
        map.data.addGeoJson({type: "Feature", geometry: area});
        map.data.addGeoJson({type: "Feature", geometry: prize});

        map.data.setStyle({
          draggable: true,
          editable: true,
          strokeColor: '#a3c1c9',
          strokeOpacity: 0.8,
          strokeWeight: 2,
          fillColor: '#a3c1c9',
          fillOpacity: 0.6,
          icon: {url: '/images/icon-prize.png', scaledSize: new google.maps.Size(16, 16)}
        });

        google.maps.event.addListener(map.data, "setgeometry", () => {
          map.data.toGeoJson(featureCollection => {
            const geometries = featureCollection.features.map(f => f.geometry);
            const area = geometries.filter(g => g.type === "Polygon")[0];
            areaEditor.dispatchEvent(new CustomEvent('area-change', {detail: area}));

            const prize = geometries.filter(g => g.type === "Point")[0];
            areaEditor.dispatchEvent(new CustomEvent('prize-change', {detail: prize}));
          });
        });


      });
    });

  }
}

function observe(node, handleAddedNode) {
  const observer = new MutationObserver(function(mutations) {
    mutations.forEach(mutation => {
      mutation.addedNodes.forEach(node => {
        handleAddedNode(node);
      });
    });
  });

  observer.observe(node, {childList: true, subtree: true});
}


const init = appRoot => {
  observe(appRoot, createEditors);
};

export default init;
