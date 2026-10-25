import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';

class Utils{

  //Goto
  static Future<dynamic> goto(BuildContext context, Widget page) {
    return Navigator.of(context).push(_animatedRouting(page));
  }

  //Push and remove previous routes
  static void gotoReplacement(BuildContext context, Widget page) {
    Navigator.of(context).popUntil((route) => false);
    Navigator.push(context, _animatedRouting(page));
  }

  //Part of GOTO Widget
  static Route _animatedRouting(Widget route) {
    return PageRouteBuilder(
      allowSnapshotting: true,
      pageBuilder: (context, animation, secondaryAnimation) => route,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Slide from the right
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  static String glCategories({required int category, required AppLocalizations locale}) {
    if (category == 1) {
      return locale.asset;
    } else if (category == 2) {
      return locale.liability;
    } else if (category == 3) {
      return locale.income;
    } else if (category == 4) {
      return locale.expense;
    } else {
      return "not found";
    }
  }

  static Future<void> copyToClipboard(String text) async {
    if (text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }
  static String genderType({required String gender, AppLocalizations? locale}) {
    if (gender == "Male") {
      return locale!.male;
    } else if (gender == "Female") {
      return locale!.female;
    } else {
      return "";
    }
  }

  // static String? validatePassword({required String value, context}) {
  //   final locale = AppLocalizations.of(context)!;
  //   if (value.length < 8) {
  //     return locale.password8Char;
  //   }
  //   if (!RegExp(r'[A-Z]').hasMatch(value)) {
  //     return locale.passwordUpperCase;
  //   }
  //   if (!RegExp(r'[a-z]').hasMatch(value)) {
  //     return locale.passwordLowerCase;
  //   }
  //   if (!RegExp(r'[0-9]').hasMatch(value)) {
  //     return locale.passwordWithDigit;
  //   }
  //   if (!RegExp(r'[!@#$%^&*()_+{}\[\]:;<>,.?/~`]').hasMatch(value)) {
  //     return locale.passwordWithSpecialChar;
  //   }
  //
  //   return null; // Password is valid
  // }
  //
  // static String? validateUsername({required String value, context}) {
  //   final locale = AppLocalizations.of(context)!;
  //
  //   // Minimum length
  //   if (value.length < 4) {
  //     return locale.usernameMinLength; // "Username must be at least 4 characters"
  //   }
  //
  //   // Cannot start with a digit
  //   if (RegExp(r'^[0-9]').hasMatch(value)) {
  //     return locale.usernameNoStartDigit; // "Username cannot start with a number"
  //   }
  //
  //   // Allowed characters: letters, digits, underscore, dot
  //   if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value)) {
  //     return locale.usernameInvalidChars; // "Username can only contain letters, numbers, . or _"
  //   }
  //
  //   // No spaces
  //   if (value.contains(' ')) {
  //     return locale.usernameNoSpaces; // "Username cannot contain spaces"
  //   }
  //
  //   return null; // Username is valid
  // }



  // static String? validateEmail({required String email, context}) {
  //   final locale = AppLocalizations.of(context)!;
  //   if (email.isNotEmpty) {
  //     // Regular expression for validating an email
  //     final RegExp emailRegex = RegExp(
  //       r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  //     );
  //     if (!emailRegex.hasMatch(email)) {
  //       return locale.emailValidationMessage;
  //     }
  //   } else {
  //     return null;
  //   }
  //
  //   return null;
  // }


  // ✅ CORRECT - Single file selection
  static Future<Uint8List?> pickImage() async {
    try {
      // Use pickFile() for single file (no 's')
      final result = await FilePicker.pickFile(
        type: FileType.image,
      );

      if (result == null) {
        return null;
      }

      // Single file result is a PlatformFile? not a list
      final file = result;
      return await file.readAsBytes();

    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }


}


