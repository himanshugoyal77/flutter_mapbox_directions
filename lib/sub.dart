import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import "./stack.dart" as st;

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage>
    with SingleTickerProviderStateMixin {
  LatLng latLng = const LatLng(19.2550777, 73.1268352);
  LatLng latLng2 = const LatLng(19.25374496359747, 73.12617533208805);
  final List<LatLng> polyLinePoints = [];
  double duration = 0;
  double distance = 0;
  List<String> instructions = [];
  final userMarkers = [];
  late AnimationController controller;
  var stack = st.Stack<AnimationController>();

  @override
  void initState() {
    super.initState();

    controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));

    getPloyLinePoints();
    _scrollController.addListener(() {
      if (_scrollController.position.atEdge) {
        if (_scrollController.position.pixels == 0) {
          print('At top');
        } else {
          print('At bottom');
        }
      }
    });
  }

  void getPloyLinePoints() async {
    const String url =
        "https://api.mapbox.com/directions/v5/mapbox/driving/73.1268352%2C19.2550777%3B73.12617533208805%2C19.25374496359747?alternatives=false&geometries=geojson&language=en&overview=full&steps=true&access_token=pk.eyJ1IjoiYXlhYW56YXZlcmkiLCJhIjoiY2ttZHVwazJvMm95YzJvcXM3ZTdta21rZSJ9.WMpQsXd5ur2gP8kFjpBo8g";
    var res = await http.get(Uri.parse(url));

    if (res.statusCode == 200) {
      var data = jsonDecode(res.body)["routes"][0];
      var geometry = data["geometry"]["coordinates"];
      var legs = data["legs"][0]["steps"];
      setState(() {
        distance = data["distance"] / 1000;
        duration = data["duration"] / 60;
      });
      for (var i = 0; i < geometry.length; i++) {
        polyLinePoints.add(LatLng(geometry[i][1], geometry[i][0]));
      }
      for (var i = 0; i < legs.length; i++) {
        instructions.add(legs[i]["maneuver"]["instruction"]);
      }
    }
  }

  final ScrollController _scrollController = ScrollController();
  final MapController mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: latLng,
                initialZoom: 18,
                maxZoom: 20,
                minZoom: 13,
                onLongPress: (tapPosition, point) {
                  stack.push(controller);
                  print(stack.top());
                  userMarkers.add(Marker(
                    point: point,
                    width: 45,
                    height: 45,
                    alignment: Alignment.topCenter,
                    child: ElasticIn(
                      delay: const Duration(milliseconds: 500),
                      controller: (controller) => this.controller = stack.top(),
                      child: FadeInDown(
                        duration: const Duration(milliseconds: 700),
                        from: 20,
                        child: Icon(
                          Icons.location_pin,
                          color: Colors.red.shade700,
                          size: 45,
                        ),
                      ),
                    ),
                  ));

                  setState(() {});
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=pk.eyJ1IjoiYXlhYW56YXZlcmkiLCJhIjoiY2ttZHVwazJvMm95YzJvcXM3ZTdta21rZSJ9.WMpQsXd5ur2gP8kFjpBo8g",
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: latLng,
                      width: 45,
                      height: 45,
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.location_pin,
                        color: Colors.red.shade700,
                        size: 45,
                      ),
                    ),
                    Marker(
                      point: latLng2,
                      width: 45,
                      height: 45,
                      alignment: Alignment.topCenter,
                      child: AnimatedOpacity(
                        duration: const Duration(seconds: 1),
                        opacity: 1,
                        child: FadeInDown(
                          child: Icon(
                            Icons.shop_outlined,
                            color: Colors.red.shade700,
                            size: 45,
                          ),
                        ),
                      ),
                    ),
                    ...userMarkers,
                  ],
                ),
                PolylineLayer(polylines: [
                  Polyline(
                    points: polyLinePoints,
                    strokeWidth: 10.0,
                    color: Colors.red.shade700,
                  ),
                ]),
              ],
            ),
            Positioned(
                top: 20,
                left: 10,
                right: 10,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                        "Distance: ${distance.toStringAsFixed(2)} km, Duration: ${duration.toStringAsFixed(2)} min",
                        style: const TextStyle(fontSize: 20)),
                  ),
                )),
            Positioned(
              bottom: 80,
              left: 10,
              right: 10,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: instructions
                      .map((e) => Container(
                            width: 200,
                            height: 120,
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title: Text(e),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            // icons to undo previous action
            Positioned(
              bottom: 140,
              right: 20,
              child: FloatingActionButton(
                onPressed: () {
                  stack.top().reverse(
                      from: stack.top().value == 0 ? 1 : stack.top().value);
                  print(stack.top());
                  userMarkers.removeLast();
                  stack.pop();
                  setState(() {});
                },
                child: const Icon(Icons.undo),
              ),
            ),

            // icons to remove markers
            Positioned(
              bottom: 20,
              left: 20,
              child: FloatingActionButton(
                onPressed: () {
                  stack.top().reverse();
                  //userMarkers.clear();
                  stack.pop();
                  print(stack.top());
                  setState(() {});
                },
                child: const Icon(Icons.delete),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            mapController.move(latLng, 18);
          },
          child: const Icon(Icons.refresh),
        ));
  }
}
