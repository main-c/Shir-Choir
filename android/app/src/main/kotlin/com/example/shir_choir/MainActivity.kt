package com.example.shir_choir

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Le plugin PDF sera automatiquement enregistré via pubspec.yaml
        // Pas besoin d'enregistrement manuel pour flutter_pdfview
    }
}
