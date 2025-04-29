import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
class QrGenerateScreen extends StatefulWidget {
  const QrGenerateScreen({super.key});

  @override
  State<QrGenerateScreen> createState() => _QrGenerateScreenState();
}

class _QrGenerateScreenState extends State<QrGenerateScreen> {
  final TextEditingController txtCntrl = TextEditingController();
  final ScreenshotController snapshotCntrl = ScreenshotController();
  String qrData = '';
  String type = 'text';
  final Map<String, TextEditingController> cntrl = {
    'name': TextEditingController(),
    'Phone': TextEditingController(),
    'email': TextEditingController(),
    'url': TextEditingController(),
  };

  String _generateData() {
    switch (type) {
      case 'contact':
        return '''FN: ${cntrl['name']?.text ?? ''}
        TEL: ${cntrl['Phone']?.text ?? ''}
        EMAIL: ${cntrl['email']?.text ?? ''}
        ''';

      case 'url':
        String url = cntrl['url']?.text ?? '';
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          url = 'https://$url';
        }
        return url;
      default:
        return txtCntrl.text;
    }
  }

  Future<void> _shareQR() async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/qr_code.png';
    final capture = await snapshotCntrl.capture();
    if (capture == null) return null;

    File imageFile = File(imagePath);
    await imageFile.writeAsBytes(capture);
    await Share.shareXFiles([XFile(imagePath)], text: "Share QR");
  }

  Widget _buildTextField(TextEditingController cntrl, String label) {
    return Padding(padding: EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: cntrl,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),

        ),
        onChanged: (_) {
          setState(() {
            qrData = _generateData();
          });
        },
      ),
    );
  }
   Widget _buildInputFields(){
    switch(type){
      case 'contact':
        return Column(
          children: [
            _buildTextField(cntrl['name']!,"Name"),
            _buildTextField(cntrl['Phone']!,"Phone"),
            _buildTextField(cntrl['email']!,"Email"),
          ],
        );
      case 'url':
        return _buildTextField(cntrl['url']!, "URL");
      default:
        return  TextField(
      controller: txtCntrl,
      enableInteractiveSelection: true,
      decoration: InputDecoration(
    labelText: "Enter Text",
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    ),

    ),
    onChanged: (value) {
    setState(() {
    qrData = value;
    });
    },
    );
    }
   }
  @override
  Widget build(BuildContext context) {
   return Scaffold(
     backgroundColor: Colors.teal,
     appBar: AppBar(
       backgroundColor: Colors.teal,
       foregroundColor: Colors.white,
       elevation: 0,
       title: Text("Generate QR Code",style: GoogleFonts.poppins(
         fontWeight: FontWeight.w600,
       )),
     ),
     body:  Container(
       padding: EdgeInsets.all(20),
       child: SingleChildScrollView(
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.center,
         children: [Card(
           shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(16),
           ),
           child: Padding(
             padding: EdgeInsets.all(15),
             child: Column(
               children: [
                 SegmentedButton<String>(
                   selected: {type},
                   onSelectionChanged: (Set<String> selection){
                     setState(() {
                       type=selection.first;
                       qrData='';
                     });
                   },
                   segments: const[
                     ButtonSegment(
                       value:'text',
                       label: Text("Text",style: TextStyle(fontSize: 20),),
                       icon: Icon(Icons.text_fields),
                     ),
                 ButtonSegment(
                   value:'url',
                   label: Text("URL",style: TextStyle(fontSize: 20),),
                   icon: Icon(Icons.link),
                 ),
                 ButtonSegment(
                   value:'contact',
                   label: Text("Contact",style: TextStyle(fontSize: 16),),
                   icon: Icon(Icons.contact_page),
                 ),
               ],
             ),
             SizedBox(height: 24),
                 _buildInputFields(),
             ],),
         ),
         ),
           SizedBox(height: 24),
           if(qrData.isNotEmpty)
             Column(
               children: [
                 Card(color: Colors.white,
                 elevation: 0,
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(16),
                   ),
                   child: Padding(
                     padding: EdgeInsets.all(16),
                     child: Column(
                       children: [
                         Screenshot( controller: snapshotCntrl,
                         child: Container(
                           color: Colors.white,
                           padding: EdgeInsets.all(16),
                           child: QrImageView(
                               data:qrData,
                               version:QrVersions.auto,
                               size:200,
                             errorCorrectionLevel: QrErrorCorrectLevel.H ,
                           ),
                         ),

                         ),
                       ],
                     ),
                   )
                 ),
                 SizedBox(height: 16),
                 ElevatedButton.icon(
                   onPressed: _shareQR,
                   icon: Icon(Icons.share),
                   label: Text("Share"),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.white,
                     padding: EdgeInsets.symmetric(
                       horizontal: 24,
                       vertical: 12,
                     ),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(12),

                     )
                   ),

                 ),
               ],
             )
    ],),
       ),
     ),
   );
  }
}


