import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:my_expense/_index.g.dart';

class MyBox {
  static Box<dynamic>? keyBox;
  static Box<dynamic>? encryptedBox;

  static Future<void> init() async {
    Log.info(message: "⌛ Init Box");

    // generate hive box for stored the jwt token
    if (keyBox == null) {
      keyBox = await Hive.openBox('storage');
    }
    else {
      // we already have keyBox, so we can compact it, close and re-open it?
      Log.info(message: "🗜 Compacting Box on init");
      await keyBox!.compact();
    }

    // check if we already have key or not?
    List<int> key;
    Uint8List keyInt;
    if (!keyBox!.containsKey('key')) {
      key = Hive.generateSecureKey();
      keyInt = key as Uint8List;
      keyBox!.put('key', key);
    } else {
      key = keyBox!.get('key');
      keyInt = key as Uint8List;
    }

    // open the encrypted box based on the key we put on the storage
    encryptedBox = await Hive.openBox(
      'vault',
      encryptionCipher: HiveAesCipher(keyInt),
    );
    await encryptedBox!.compact();
  }

  static Future<void> putString({
    required String key,
    required String value,
  }) async {
    // check if null
    if(keyBox == null) {
      await init();
    }

    // not null, means we can put the data on the keyBox
    await keyBox!.put(key, value);
  }

  static Future<void> putStringList({
    required String key,
    required List<String> value
  }) async {
    // check if null
    if(keyBox == null) {
      await init();
    }

    // not null, means we can put the data on the keyBox
    await keyBox!.put(key, value);
  }

  static String? getString({
    required String key
  }) {
    // check if null
    if(keyBox == null) {
      init();
    }

    // check if got the key or not?
    if(keyBox!.containsKey(key)) {
      return keyBox!.get(key).toString();
    }
    else {
      return null;
    }
  }

  static List<String>? getStringList({required String key}) {
    // check if null
    if(keyBox == null) {
      init();
    }

    // check if got the key or not?
    if(keyBox!.containsKey(key)) {
      return List<String>.from(keyBox!.get(key));
    }
    else {
      return null;
    }
  }

  static Future<void> putBool({
    required String key,
    required bool value
  }) async {
    // check if null
    if(keyBox == null) {
      init();
    }

    await keyBox!.put(key, value);
  }

  static bool getBool({required String key}) {
    // check if null
    if(keyBox == null) {
      init();
    }

    if (keyBox!.containsKey(key)) {
      return keyBox!.get(key);
    }
    else {
      return false;
    }
  }

  static List<String> getKeys({required String key}) {
    List<String> result = [];
    String currentKey = "";
    var keys = keyBox!.keys;
    if(keys.isNotEmpty) {
      for (var keyDynamic in keys) {
        currentKey = keyDynamic.toString();
        if(currentKey.contains(key)) {
          result.add(currentKey);
        }
      }
    }
    return result;
  }

  static Future<void> clear() async {
    if(keyBox != null) {
      // clear the keyBox
      var keys = keyBox!.keys;
      for (var key in keys) {
        // skip the "key" as this is hold the encryption key for our encryptedBox
        // if we removed the key, it will got error during logon as we cannot re-open the
        // encrypted box and need to recreate it.
        if(key.toString().toLowerCase() != "key") {
          keyBox!.delete(key);
        }
      }
      await keyBox!.compact();
      
      // delete the jwt from encrypted box
      if(encryptedBox != null) {
        if(encryptedBox!.containsKey("jwt")) {
          encryptedBox!.delete("jwt");
        }
      }
      await encryptedBox!.compact();
    }
  }

  static Future<void> delete({
    required String key,
    bool exact = false,
  }) async {
    if(exact) {
      // check if got key on the key box or not?
      if(keyBox!.containsKey(key)) {
        // can be deleted
        keyBox!.delete(key);
      }
    }
    else {
      // get all the keys and find if the key string is on the key or not?
      var keys = keyBox!.keys;
      for (var keyDynamic in keys) {
        String key = keyDynamic.toString();
        if(key.contains(key)) {
          // delete this data
          keyBox!.delete(key);
        }
      }
    }
  }
}