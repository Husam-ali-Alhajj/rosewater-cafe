package com.example.rosewater_cafe

// Sprint 8 Task 5: local_auth's BiometricPrompt needs a FragmentActivity,
// not a plain Activity -- FlutterFragmentActivity is Flutter's own
// FragmentActivity-based embedding, a drop-in replacement for
// FlutterActivity for exactly this reason.
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
