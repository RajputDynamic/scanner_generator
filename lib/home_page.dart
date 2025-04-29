import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanner_generator/qr_generate_screen.dart';
import 'package:scanner_generator/qr_scanner_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: Colors.teal,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20),
            Padding(
                padding: EdgeInsets.all(24),
              child: Text("QR CODE ",style: GoogleFonts.poppins(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.white,

              ),),
            ),
            SizedBox(height: 50,),
            Center(
              child:  Container(
                padding: EdgeInsets.all(50),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:  BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withBlue(0),
                      blurRadius: 10,
                      spreadRadius: 5,
                    )
                  ]
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildFeatureButton(
                      context,
                      "Generate QR",
                      Icons.qr_code_2,
                        ()=> Navigator.push(context,
                          MaterialPageRoute( builder: (context)=>const QrGenerateScreen() )),
                    ),
                    SizedBox(height: 40,),
                    _buildFeatureButton(
                      context,
                      "Scan QR",
                      Icons.qr_code_scanner_rounded,
                          ()=> Navigator.push(context,
                          MaterialPageRoute( builder: (context)=>const QrScannerScreen() )),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      )
    );
  }
  Widget _buildFeatureButton(BuildContext context,String title,IconData icon,
                 VoidCallback onPressed){
    return GestureDetector(
               onTap: onPressed  ,
               child: Container(
                   padding: EdgeInsets.all(15),
                      width:250,
                      height: 200,
                 decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(15),
                 ),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                            Icon(icon,size:90,color:Colors.white),
                           Text(title,style: GoogleFonts.poppins(
                             fontSize: 30,
                             fontWeight: FontWeight.bold,
                             color: Colors.white,
                           ),
                           )
  ],
  )
  ),
    );
  }
}

