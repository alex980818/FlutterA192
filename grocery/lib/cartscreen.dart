import 'dart:async';
import 'dart:convert';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:grocery/user.dart';
import 'package:http/http.dart' as http;
import 'package:toast/toast.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoder/geocoder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CartScreen extends StatefulWidget {
  final User user;

  const CartScreen({Key key, this.user}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List cartData;
  double screenHeight, screenWidth;
  bool _selfPickup = true;
  bool _storeCredit = false;
  bool _homeDelivery = false;
  double _weight = 0.0, _totalprice = 0.0;
  Position _currentPosition;
  String curaddress;
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController gmcontroller;
  CameraPosition _home;
  MarkerId markerId1 = MarkerId("12");
  Set<Marker> markers = Set();
  double latitude, longitude;
  String label;
  CameraPosition _userpos;
  double deliverycharge;
  double amountpayable;

  @override
  void initState() {
    super.initState();
    _getLocation();
    //_getCurrentLocation();
    _loadCart();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    if (cartData == null) {
      return Scaffold(
          appBar: AppBar(
            title: Text('My Cart'),
          ),
          body: Container(
              child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                CircularProgressIndicator(),
                SizedBox(
                  height: 10,
                ),
                Text(
                  "Loading Your Cart",
                  style: TextStyle(fontWeight: FontWeight.bold),
                )
              ],
            ),
          )));
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Cart'),
        ),
        body: ListView.builder(
            itemCount: cartData == null ? 1 : cartData.length + 2,
            itemBuilder: (context, index) {
              if (index == cartData.length) {
                return Container(
                    height: screenHeight / 2.4,
                    width: screenWidth / 2.5,
                    child: InkWell(
                      onLongPress: () => {print("Delete")},
                      child: Card(
                        color: Colors.yellow,
                        elevation: 5,
                        child: Column(
                          children: <Widget>[
                            SizedBox(
                              height: 10,
                            ),
                            Text("Delivery Option",
                                style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold)),
                            Text("Weight:" + _weight.toString() + " KG",
                                style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold)),
                            Expanded(
                                child: Row(
                              children: <Widget>[
                                Container(
                                  // color: Colors.red,
                                  width: screenWidth / 2,
                                  height: screenHeight / 3,
                                  child: Column(
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Checkbox(
                                            value: _selfPickup,
                                            onChanged: (bool value) {
                                              _onSelfPickUp(value);
                                            },
                                          ),
                                          Text("Self Pickup"),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                    padding: EdgeInsets.fromLTRB(2, 1, 2, 1),
                                    child: SizedBox(
                                        width: 2,
                                        child: Container(
                                          height: screenWidth / 2,
                                          color: Colors.grey,
                                        ))),
                                Expanded(
                                    child: Container(
                                  //color: Colors.blue,
                                  width: screenWidth / 2,
                                  height: screenHeight / 3,
                                  child: Column(
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Checkbox(
                                            value: _homeDelivery,
                                            onChanged: (bool value) {
                                              _onHomeDelivery(value);
                                            },
                                          ),
                                          Text("Home Delivery"),
                                        ],
                                      ),
                                      FlatButton(
                                        color: Colors.blue,
                                        onPressed: () => {_loadMapDialog()},
                                        child: Icon(
                                          MdiIcons.locationEnter,
                                          color: Colors.red,
                                        ),
                                      ),
                                      Text("Current Address:",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Row(
                                        children: <Widget>[
                                          Text("  "),
                                          Flexible(
                                            child: Text(
                                              curaddress ?? "Address not set",
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ))
                          ],
                        ),
                      ),
                    ));
              }
              if (index == cartData.length + 1) {
                return Container(
                    height: screenHeight / 3,
                    child: Card(
                      elevation: 5,
                      child: Column(
                        children: <Widget>[
                          SizedBox(
                            height: 10,
                          ),
                          Text("Payment",
                              style: TextStyle(
                                  fontSize: 20.0, fontWeight: FontWeight.bold)),
                          SizedBox(height: 10),
                          Text(
                              "Total Item Price RM " +
                                      _totalprice.toStringAsFixed(2) ??
                                  "0.0",
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              )),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                              "Delivery Charge RM " +
                                      deliverycharge.toStringAsFixed(2) ??
                                  "0.0",
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              )),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Checkbox(
                                value: _storeCredit,
                                onChanged: (bool value) {
                                  _onStoreCredit(value);
                                },
                              ),
                              Text("Store Credit Available RM " +
                                  widget.user.credit),
                            ],
                          ),
                          Text(
                              "Total Amount Charge RM " +
                                      amountpayable.toStringAsFixed(2) ??
                                  "0.0",
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              )),
                          SizedBox(
                            height: 10,
                          ),
                          MaterialButton(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0)),
                            minWidth: 300,
                            height: 50,
                            child: Text('Make Payment'),
                            color: Colors.blue[500],
                            textColor: Colors.white,
                            elevation: 10,
                            onPressed: makePayment,
                          ),
                        ],
                      ),
                    ));
              }
              index -= 0;
              return Card(
                  elevation: 10,
                  child: Padding(
                      padding: EdgeInsets.all(5),
                      child: Row(children: <Widget>[
                        Column(
                          children: <Widget>[
                            Container(
                                height: screenWidth / 4.8,
                                width: screenWidth / 4.8,
                                decoration: BoxDecoration(
                                    //shape: BoxShape.circle,
                                    //border: Border.all(color: Colors.black),
                                    image: DecorationImage(
                                        fit: BoxFit.fill,
                                        image: NetworkImage(
                                            "http://slumberjer.com/grocery/productimage/${cartData[index]['id']}.jpg")))),
                            Text(
                              "RM " + cartData[index]['price'],
                            ),
                          ],
                        ),
                        Padding(
                            padding: EdgeInsets.fromLTRB(5, 1, 10, 1),
                            child: SizedBox(
                                width: 2,
                                child: Container(
                                  height: screenWidth / 3.5,
                                  color: Colors.grey,
                                ))),
                        Container(
                            width: screenWidth / 1.45,
                            //color: Colors.blue,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Flexible(
                                  child: Column(
                                    children: <Widget>[
                                      Text(
                                        cartData[index]['name'],
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                        maxLines: 1,
                                      ),
                                      Text("Available " +
                                          cartData[index]['quantity'] +
                                          " unit"),
                                      Text("Your Quantity " +
                                          cartData[index]['cquantity']),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          FlatButton(
                                            onPressed: () =>
                                                {_updateCart(index, "add")},
                                            child: Icon(
                                              MdiIcons.plus,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(cartData[index]['cquantity']),
                                          FlatButton(
                                            onPressed: () =>
                                                {_updateCart(index, "remove")},
                                            child: Icon(
                                              MdiIcons.minus,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text("RM " + cartData[index]['yourprice'],
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                )
                              ],
                            )),
                      ])));
            }),
      );
    }
  }

  void _loadCart() {
    _weight = 0.0;
    _totalprice = 0.0;
    amountpayable = 0.0;
    deliverycharge = 0.0;
    ProgressDialog pr = new ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false);
    pr.style(message: "Updating cart...");
    pr.show();
    String urlLoadJobs = "https://slumberjer.com/grocery/php/load_cart.php";
    http.post(urlLoadJobs, body: {
      "email": widget.user.email,
    }).then((res) {
      print(res.body);
      pr.dismiss();
      setState(() {
        var extractdata = json.decode(res.body);
        cartData = extractdata["cart"];
        for (int i = 0; i < cartData.length; i++) {
          _weight = double.parse(cartData[i]['weight']) *
                  int.parse(cartData[i]['cquantity']) +
              _weight;
          _totalprice = double.parse(cartData[i]['yourprice']) + _totalprice;
        }
        _weight = _weight/1000;
        amountpayable = _totalprice;

        print(_weight);
        print(_totalprice);
      });
    }).catchError((err) {
      print(err);
      pr.dismiss();
    });
    pr.dismiss();
  }

  _updateCart(int index, String op) {
    int curquantity = int.parse(cartData[index]['quantity']);
    int quantity = int.parse(cartData[index]['cquantity']);
    if (op == "add") {
      quantity++;
      if (quantity > (curquantity - 2)) {
        Toast.show("Quantity not available", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
        return;
      }
    }
    if (op == "remove") {
      quantity--;
      if (quantity == 0) {
        _deleteCart(index);
        return;
      }
    }
    String urlLoadJobs = "https://slumberjer.com/grocery/php/update_cart.php";
    http.post(urlLoadJobs, body: {
      "email": widget.user.email,
      "prodid": cartData[index]['id'],
      "quantity": quantity.toString()
    }).then((res) {
      print(res.body);
      if (res.body == "success") {
        Toast.show("Cart Updated", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
        _loadCart();
      } else {
        Toast.show("Failed", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
      }
    }).catchError((err) {
      print(err);
    });
  }

  _deleteCart(int index) {
    showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('Delete item?'),
        actions: <Widget>[
          MaterialButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                http.post("https://slumberjer.com/grocery/php/delete_cart.php",
                    body: {
                      "email": widget.user.email,
                      "prodid": cartData[index]['id'],
                    }).then((res) {
                  print(res.body);
                  if (res.body == "success") {
                    _loadCart();
                  } else {
                    Toast.show("Failed", context,
                        duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
                  }
                }).catchError((err) {
                  print(err);
                });
              },
              child: Text("Yes")),
          MaterialButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text("Cancel")),
        ],
      ),
    );
  }

  void _onSelfPickUp(bool newValue) => setState(() {
        _selfPickup = newValue;
        if (_selfPickup) {
          _homeDelivery = false;
          _updatePayment();
        } else {
          //_homeDelivery = true;
          _updatePayment();
        }
      });

  void _onStoreCredit(bool newValue) => setState(() {
        _storeCredit = newValue;
              });

  void _onHomeDelivery(bool newValue) {
    //_getCurrentLocation();
    _getLocation();
    setState(() {
      _homeDelivery = newValue;
      if (_homeDelivery) {
        _updatePayment();
        _selfPickup = false;
      } else {
        _updatePayment();
      }
    });
  }

  _getLocation() async {
    final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
    _currentPosition = await geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    //debugPrint('location: ${_currentPosition.latitude}');
    final coordinates =
        new Coordinates(_currentPosition.latitude, _currentPosition.longitude);
    var addresses =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);
    var first = addresses.first;
    setState(() {
      curaddress = first.addressLine;
      if (curaddress != null) {
        latitude = _currentPosition.latitude;
        longitude = _currentPosition.longitude;
        return;
      }
    });

    print("${first.featureName} : ${first.addressLine}");
  }

  _getLocationfromlatlng(double lat, double lng, newSetState) async {
    final Geolocator geolocator = Geolocator()
      ..placemarkFromCoordinates(lat, lng);
    _currentPosition = await geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    //debugPrint('location: ${_currentPosition.latitude}');
    final coordinates = new Coordinates(lat, lng);
    var addresses =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);
    var first = addresses.first;
    newSetState(() {
      curaddress = first.addressLine;
      if (curaddress != null) {
        latitude = _currentPosition.latitude;
        longitude = _currentPosition.longitude;
        return;
      }
    });
    setState(() {
      curaddress = first.addressLine;
      if (curaddress != null) {
        latitude = _currentPosition.latitude;
        longitude = _currentPosition.longitude;
        return;
      }
    });

    print("${first.featureName} : ${first.addressLine}");
  }

  _loadMapDialog() {
    try {
      if (_currentPosition.latitude == null) {
        Toast.show("Location not available. Please wait...", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
        _getLocation(); //_getCurrentLocation();
        return;
      }
      _controller = Completer();
      _userpos = CameraPosition(
        target: LatLng(latitude, longitude),
        zoom: 14.4746,
      );

      markers.add(Marker(
          markerId: markerId1,
          position: LatLng(latitude, longitude),
          infoWindow: InfoWindow(
            title: 'Current Location',
            snippet: 'Delivery Location',
          )));

      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, newSetState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20.0))),
                title: Text("Select New Delivery Location"),
                titlePadding: EdgeInsets.all(5),
                //content: Text(curaddress),
                actions: <Widget>[
                  Text(curaddress),
                  Container(
                    height: screenHeight / 2 ?? 600,
                    width: screenWidth ?? 360,
                    child: GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: _userpos,
                        markers: markers.toSet(),
                        onMapCreated: (controller) {
                          _controller.complete(controller);
                        },
                        onTap: (newLatLng) {
                          _loadLoc(newLatLng, newSetState);
                        }),
                  ),
                  MaterialButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0)),
                    //minWidth: 200,
                    height: 30,
                    child: Text('Close'),
                    color: Colors.blue[500],
                    textColor: Colors.white,
                    elevation: 10,
                    onPressed: () =>
                        {markers.clear(), Navigator.of(context).pop(false)},
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      print(e);
      return;
    }
  }

  void _loadLoc(LatLng loc, newSetState) async {
    newSetState(() {
      print("insetstate");
      markers.clear();
      latitude = loc.latitude;
      longitude = loc.longitude;
      _getLocationfromlatlng(latitude, longitude, newSetState);
      _home = CameraPosition(
        target: loc,
        zoom: 14,
      );
      markers.add(Marker(
          markerId: markerId1,
          position: LatLng(latitude, longitude),
          infoWindow: InfoWindow(
            title: 'New Location',
            snippet: 'New Delivery Location',
          )));
    });
    _userpos = CameraPosition(
      target: LatLng(latitude, longitude),
      zoom: 14.4746,
    );
    _newhomeLocation();
  }

  Future<void> _newhomeLocation() async {
    gmcontroller = await _controller.future;
    gmcontroller.animateCamera(CameraUpdate.newCameraPosition(_home));
    //Navigator.of(context).pop(false);
    //_loadMapDialog();
  }

  void _updatePayment() {
    _weight = 0.0;
    _totalprice = 0.0;
    amountpayable = 0.0;
    setState(() {
      for (int i = 0; i < cartData.length; i++) {
        _weight = double.parse(cartData[i]['weight']) *
                int.parse(cartData[i]['cquantity']) +
            _weight;
        _totalprice = double.parse(cartData[i]['yourprice']) + _totalprice;
      }
      _weight = _weight / 1000;
      print(_selfPickup);
      if (_selfPickup) {
        deliverycharge = 0.0;
      } else {
        if (_totalprice > 100) {
          deliverycharge = 5.00;
        } else {
          deliverycharge = _weight * 0.5;
        }
      }
      if (_homeDelivery) {
        if (_totalprice > 100) {
          deliverycharge = 5.00;
        } else {
          deliverycharge = _weight * 0.5;
        }
      }
      amountpayable = deliverycharge + _totalprice;

      print(_weight);
      print(_totalprice);
    });
  }

  void makePayment() {
    if (_selfPickup) {
      print("PICKUP");
      Toast.show("Self Pickup", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
    } else if (_homeDelivery) {
      print("HOME DELIVERY");
      Toast.show("Home Delivery", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
    } else {
      Toast.show("Please select delivery option", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
    }
  }
}
