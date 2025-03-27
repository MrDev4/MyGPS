import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isButtonDisabled = false;

   String _message = 'Appuyez pour récupérer la localisation et envoyé';
  
  //Formulaire
  final _userName = TextEditingController();

  Future<void> _getAndSendLocation() async {
    try {
      // Récupérer la position
      Position position = await getLocation();
      setState(() {
        _message = 'Latitude: ${position.latitude}, Longitude: ${position.longitude}';
      });

      // Envoyer la position à l'API
      await _submitForm(position);
    } catch (e) {
      setState(() {
        _message = 'Erreur: $e';
      });
    }
  }

  Future<Position> getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Le service de localisation est désactivé.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permission de localisation refusée');
      }
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return position;
  }

  Future<void> _submitForm(Position position) async {

    final String userName = _userName.text;

    if (userName.isEmpty) {
      //
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Specifier votre nom")),
      );
      setState(() {
        isButtonDisabled = false;
      });
      return;
    }

    try {
      const url = 'http://mygps.dev-mampolo.com/mobile-api/insertPosition.php';
      final uri = Uri.parse(url);

      final responseText = await http.post(uri, body: {
        "userName":userName.toString(),
        "latitude": position.latitude.toString(),
        "longitude": position.longitude.toString(),
      });

      if(responseText.statusCode == 200) {
        var data = jsonDecode(responseText.body);
        if (data["success"] == "true")
        {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Données envoyés")),
          );
          // Navigator.pop(context);
          setState(() {
            isButtonDisabled = false;
          });
          return;
        }else{
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${data["message"]}"), backgroundColor: Colors.red,),
          );
          setState(() {
            isButtonDisabled = false;
          });
          return;
        }
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de l'envoi")),
        );
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Problème avec le serveur distant")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Où es-tu ?"),),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.all(8.0),
                  child: Text("Remplit et envoit ta position", style: TextStyle(fontWeight: FontWeight.bold),)
                ),
          
                //userName
                Container(
                  margin: EdgeInsets.all(10), 
                  child: Text("Votre nom & prenom:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                )),
                Container(
                  margin: const EdgeInsets.all(10),
                  child: TextFormField(
                    controller: _userName,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        label: Text('Text value')
                    ),
                  ),
                ),
          
                Container(
                  margin: EdgeInsets.all(10), 
                  child: Text(_message,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                )),
          
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * .5,
                    height: 50,
                    margin: const EdgeInsets.all(10),
                    child: ElevatedButton(
                        onPressed: (){
                          if(isButtonDisabled == true)
                          {
                            return;
                          }
                          setState(() {
                            isButtonDisabled = true;
                          });
                          _getAndSendLocation();
                        },
                        child: isButtonDisabled
                        ? CircularProgressIndicator()
                        : const Text("Save"),
                    ),
                  ),
                ),
          
                SizedBox(height: 15.0,)
          
              ],
            ),
          ),
        ),
      );
  }
}