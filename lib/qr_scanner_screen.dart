import 'package:flutter/material.dart';

import 'package:flutter_contacts/flutter_contacts.dart' as contacts;
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
 class QrScannerScreen extends StatefulWidget {
   const QrScannerScreen({super.key});
 
   @override
   State<QrScannerScreen> createState() => _QrScannerScreenState();
 }
class QrBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final Rect outerRect = Rect.fromLTWH(50, 200, size.width - 100, 250);

    canvas.drawRect(outerRect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
 
 class _QrScannerScreenState extends State<QrScannerScreen> {

   bool hasPermission = false;
   bool isFlashOn = false;

   late MobileScannerController scanCntrl;


   @override
   void initState() {
     super.initState();
     scanCntrl = MobileScannerController();
     _checkPermission();
   }

   @override
   void dispose() {
     scanCntrl.dispose();
     super.dispose();
   }

   Future<void> _checkPermission() async {
     final status = await Permission.camera.request();
     setState(() {
       hasPermission = status.isGranted;
     });
   }

     Future<void> _processScannedData(String? data) async {
       if (data == null) return;
        scanCntrl.stop();


       String type = 'text';
       if(data.startsWith(' ')) {
         type = 'contact';
       }
       else if (data.startsWith('https://') || data.startsWith('https://')) {
         type = 'url';
       }

       showModalBottomSheet(
           context: context,
           isScrollControlled: true,
           backgroundColor: Colors.transparent,
           builder: (context) =>
               DraggableScrollableSheet(
                 initialChildSize: 0.6,
                 minChildSize: 0.4,
                 maxChildSize: 0.9,
                 builder: (context, scrollCntrl) =>
                     Container(
                       decoration: BoxDecoration(
                         color: Theme
                             .of(context)
                             .colorScheme
                             .surface,
                         borderRadius: BorderRadius.vertical(
                             top: Radius.circular(24)),
                       ),
                       padding: EdgeInsets.all(24),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Center(
                             child: Container(
                               width: 40,
                               height: 4,
                               margin: EdgeInsets.only(bottom: 24),
                               decoration: BoxDecoration(
                                 color: Colors.grey[300],
                                 borderRadius: BorderRadius.circular(2),
                               ),
                             ),
                           ),
                           Text("Scanned Result : ",
                               style: Theme
                                   .of(context)
                                   .textTheme
                                   .headlineSmall),
                           SizedBox(height: 16),
                           Text("Type :  ${type.toUpperCase()}",
                             style: Theme.of(context).textTheme.titleMedium?.copyWith(
                               color: Theme.of(context).colorScheme.primary,
                             ),
                           ),
                           SizedBox(height: 16),
                           Expanded(child: SingleChildScrollView(
                             controller: scrollCntrl,
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 SelectableText(data,
                                     style: Theme
                                         .of(context)
                                         .textTheme
                                         .bodyLarge),
                                 SizedBox(height: 24),
                                 if (type == 'url')
                                   ElevatedButton.icon(
                                     onPressed: () {
                                        _launcherURL(data);
                                   },
                                     icon: Icon(Icons.open_in_new),
                                     label: Text("Open URL"),
                                     style: ElevatedButton.styleFrom(
                                       minimumSize: Size.fromHeight(40),
                                     ),
                                   ),
                                 if(type == 'contact')
                                   ElevatedButton.icon(
                                     onPressed: () {
                                      _saveContact(data);
                                     },
                                     icon: Icon(Icons.save_alt_outlined),
                                     label: Text("Save"),
                                     style: ElevatedButton.styleFrom(
                                       minimumSize: Size.fromHeight(40),
                                     ),
                                   ),

                               ],
                             ),
                           ),),
                           SizedBox(height: 16),
                           Row(
                             children: [
                               Expanded(child: OutlinedButton.icon(
                                 onPressed: () {
                                   Share.share(data);
                                 },
                                 icon: Icon(Icons.share_outlined),
                                 label: Text("share"),),
                               ),
                               SizedBox(height: 16),
                               Expanded(child: OutlinedButton.icon(
                                 onPressed: () {
                                   Navigator.pop(context);
                                   scanCntrl.start();
                                 },
                                 icon: Icon(Icons.qr_code_scanner_sharp),
                                 label: Text("Scan Again"),
                               ),
                               ),
                             ],

                           ),
                         ],
                       ),
                     ),
               ),
       );
     }
     Future<void> _launcherURL(String url) async {
       if (await canLaunchUrl(Uri.parse(url))) {
         await launchUrl(Uri.parse(url));
       }
     }
     Future<void> _saveContact(String vcardData) async {
       final lines = vcardData.split('\n');
       String ? name, phone, email;
       for (var line in lines) {
         if (line.startsWith('FN:')) name = line.substring(3);
         if (line.startsWith('TEL:')) phone = line.substring(4);
         if (line.startsWith('EMAIL:')) email = line.substring(5);
       }
       final contact = contacts.Contact()
         ..name.first = name ?? ''
         ..phones = [contacts.Phone(phone ?? '')]
         ..emails = [contacts.Email(email ?? '')];

       try {
         await contact.insert();
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Contact Saved!")),
         );
       }
       catch (e) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Failed!")),
         );
       }
     }
     @override
     Widget build(BuildContext context) {
       if (!hasPermission) {
         return Scaffold(
           backgroundColor: Colors.teal,
           appBar: AppBar(
             title: Text("Scanner", style: GoogleFonts.poppins(
               fontWeight: FontWeight.w500,
               fontSize: 32,
               color: Colors.white,
             ) ,),
             backgroundColor: Colors.teal,
             foregroundColor: Colors.white,
           ),
           body: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             crossAxisAlignment: CrossAxisAlignment.center,
             children: [
                 Center(
                   child: SizedBox(
                     height: 350,
                     child: Card(
                       elevation: 0,
                       color: Colors.white,
                       child: Padding(padding: EdgeInsets.all(30),
                         child: Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             Icon(Icons.camera_alt_rounded,
                             size: 64,
                               color: Colors.black38,
                             ),
                             SizedBox(height: 16),
                             Text("Camera Permission Is Required"),
                             SizedBox(height: 16),
                             ElevatedButton(
                                 onPressed: _checkPermission,
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: Colors.teal,
                                   foregroundColor: Colors.white),
                              child: Text("Grant Permission",style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w400,
                              ),),
                                   
                                 ),
                           ],
                         ),

                       )

                     ),

                   ),
                 )
             ],
           ),
         );
       }
       else{
         return Scaffold(
           backgroundColor: Colors.teal,
           appBar: AppBar(
             title: Text("Scan QR", style: GoogleFonts.poppins(
               fontWeight: FontWeight.w500,
               fontSize: 32,
               color: Colors.white,
             ) ,),
             backgroundColor: Colors.teal,
             foregroundColor: Colors.white,
             actions: [
               IconButton(onPressed: (){
                 setState(() {
                   isFlashOn=!isFlashOn;
                   scanCntrl.toggleTorch();
                 });
               }, icon: Icon(isFlashOn? Icons.flash_on_rounded: Icons.flash_off_rounded,size: 32,),
               )
             ],
           ),
           body: Stack(
             children: [
               MobileScanner(
                 controller: scanCntrl,
                 onDetect: (capture){
                   final barcode=capture.barcodes.first;
                   if(barcode.rawValue !=null){
                     final String code= barcode.rawValue!;
                     _processScannedData(code);

                   }
                 },
               ),
               Positioned.fill(
                 child: CustomPaint(
                   painter: QrBorderPainter(),
                 ),
               ),
               Positioned(
                 bottom: 24,
                   left: 0,
                 right: 0,
                 child: Center(child: Text(
                   'Align QR Code within the frame',
                   style: TextStyle(
                     color: Colors.white,
                     backgroundColor: Colors.black38,
                     fontSize: 25,
                     fontWeight: FontWeight.w500,
                   ),
                 ),
                 ),
               ),
             ],
           )
         );
       }
     }
   }
