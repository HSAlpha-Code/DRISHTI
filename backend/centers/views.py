from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from centers.models import InstituteCenter
from centers.serializers import InstituteCenterSerializer

class InstituteCenterViewSet(viewsets.ModelViewSet):
    queryset = InstituteCenter.objects.all()
    serializer_class = InstituteCenterSerializer

    @action(detail=False, methods=['get'])
    def geojson_features(self, request):
        """Returns centers formatted as GeoJSON FeatureCollection for Leaflet GIS rendering."""
        centers = self.get_queryset()
        features = []
        for c in centers:
            features.append({
                "type": "Feature",
                "geometry": {
                    "type": "Polygon",
                    "coordinates": [c.boundary_geojson] if isinstance(c.boundary_geojson, list) and len(c.boundary_geojson) > 0 and isinstance(c.boundary_geojson[0], list) else [[
                        [c.longitude - 0.002, c.latitude - 0.002],
                        [c.longitude + 0.002, c.latitude - 0.002],
                        [c.longitude + 0.002, c.latitude + 0.002],
                        [c.longitude - 0.002, c.latitude + 0.002],
                        [c.longitude - 0.002, c.latitude - 0.002],
                    ]]
                },
                "properties": {
                    "id": c.id,
                    "name": c.name,
                    "code": c.code,
                    "district": c.district,
                    "state": c.state,
                    "latitude": c.latitude,
                    "longitude": c.longitude,
                    "capacity": c.expected_capacity,
                    "current_headcount": c.current_headcount,
                    "risk_score": c.risk_score,
                    "risk_level": c.risk_level,
                    "cctv_stream_url": c.cctv_stream_url,
                }
            })

        return Response({
            "type": "FeatureCollection",
            "features": features
        })

    @action(detail=True, methods=['post'])
    def verify_gps_boundary(self, request, pk=None):
        """
        Hardware GPS Verification Endpoint.
        Checks if inspector's GPS lat/lng is within hardware site boundary polygon.
        """
        center = self.get_object()
        lat = request.data.get('latitude')
        lng = request.data.get('longitude')

        if lat is None or lng is None:
            return Response({'error': 'Latitude and Longitude are required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            lat = float(lat)
            lng = float(lng)
        except ValueError:
            return Response({'error': 'Invalid float coordinate'}, status=status.HTTP_400_BAD_REQUEST)

        is_inside = center.is_within_boundary(lat, lng)

        return Response({
            'center_code': center.code,
            'center_name': center.name,
            'inspector_gps': {'latitude': lat, 'longitude': lng},
            'boundary_verified': is_inside,
            'unlocked': is_inside,
            'message': 'Inspector GPS verified within site boundary.' if is_inside else 'GPS Hardware verification failed. You are outside the designated site boundary.'
        })
