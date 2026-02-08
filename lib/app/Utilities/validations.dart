import 'package:get/get.dart';

class Validations {
  static String? emptyVerification(String name, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "$name can not be empty";
    }
    return null;
  }

  static String? pincodeVerification(String name, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "$name can not be empty";
    }
    if (value.length != 6) {
      return "Please Enter Valid Pincode";
    }
    return null;
  }

  static String? emptyQuestionVerification(String name, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "$name can not be empty";
    } else if (value.trim().length >= 200) {
      return "$name can not be more than 200 words";
    }

    return null;
  }

  static String? addressVerification(String name, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "$name can not be empty";
    }

    return null;
  }

  static String? phoneNumberVerification(String? number, String name) {
    if (number == null || number.trim().isEmpty) {
      return "$name can not be empty";
    } else if (number.length <= 9 || number.length >= 15) {
      return "$name must be betweeen 10 to 15 characters";
    }
    return null;
  }

  static String? emailVerification(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email cannot be empty.';
    } else if (email.trim().length >= 45) {
      return "Email can not be more than 45 words";
    } else if (!email.isEmail) {
      return "Please Enter Valid Email";
    }

    return null;
  }

  static String? passVerification(String? password, {String? confirmPassword}) {
    if (password == null || password.trim().isEmpty) {
      return 'Password cannot be empty.';
    } else if (password.trim().length < 8) {
      return 'Password must contain atleast 8 characters .';
    } else if (password.trim().length > 20) {
      return "Password cannot be more than 20 character";
    }
    final passRegExp = RegExp(
      r'^(?=.*?[a-z])(?=.*?[A-Z])(?=.*?[0-9])(?=.*?[\W_]).+$',
    );

    if (!passRegExp.hasMatch(password)) {
      return 'Password must contain atleast one Capital letter, number and special character.';
    }
    if (confirmPassword != null && password != confirmPassword.trim()) {
      return 'Password didn\'t match. Try again';
    }

    return null;
  }

  static String? dropDownFieldVerification(String? value, String? name) {
    if (value == null || value.trim().isEmpty) {
      return "Please Select One $name ";
    }
    return null;
  }

  static String? aboutVerification(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // About is optional
    }
    if (value.isEmpty) {
      return "About cannot be empty";
    }
    if (value.length > 139) {
      return "About must be between 1 and 139 characters";
    }
    return null;
  }

  static String? descriptionVerification(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Description is optional
    }
    if (value.length > 512) {
      return "Description cannot be more than 512 characters";
    }
    return null;
  }

  static String? emailVerificationMeta(String? email) {
    if (email == null || email.trim().isEmpty) {
      return null; // Email is optional
    }
    if (email.length > 128) {
      return "Email cannot be more than 128 characters";
    }
    if (!email.isEmail) {
      return "Please enter a valid email";
    }
    return null;
  }

  static String? addressVerificationMeta(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Address is optional
    }
    if (value.length > 256) {
      return "Address cannot be more than 256 characters";
    }
    return null;
  }

  static String? websiteVerification(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Websites are optional
    }
    if (value.length > 256) {
      return "Website URL cannot be more than 256 characters";
    }
    // Basic URL validation
    final urlRegex = RegExp(r'^https?://');
    if (!urlRegex.hasMatch(value)) {
      return "Website must start with http:// or https://";
    }
    return null;
  }

  static String? verticalVerification(String? value) {
    if (value == null || value.trim().isEmpty || value == 'Select industry') {
      return null; // Vertical is optional
    }
    final allowedValues = [
      'UNDEFINED',
      'OTHER',
      'AUTO',
      'BEAUTY',
      'APPAREL',
      'EDU',
      'ENTERTAIN',
      'EVENT_PLAN',
      'FINANCE',
      'GROCERY',
      'GOVT',
      'HOTEL',
      'HEALTH',
      'NONPROFIT',
      'PROF_SERVICES',
      'RETAIL',
      'TRAVEL',
      'RESTAURANT',
      'NOT_A_BIZ',
    ];
    if (!allowedValues.contains(value)) {
      return "Please select a valid industry";
    }
    return null;
  }
}
