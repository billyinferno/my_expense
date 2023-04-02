import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';

class MyBox {
  static Box<dynamic>? keyBox;
  static Box<dynamic>? encryptedBox;

  static Future<void> init() async {
    print("⌛ Init Box");

    // generate hive box for stored the jwt token
    if (keyBox == null) {
      keyBox = await Hive.openBox('storage');
    }
    else {
      // we already have keyBox, so we can compact it, close and re-open it?
      print("🗜 Compacting Box on init");
      await keyBox!.compact();
    }

    // check if we already have key or not?
    var _key;
    var _keyInt;
    if (!keyBox!.containsKey('key')) {
      //print("HIVE : key not exists");
      _key = Hive.generateSecureKey();
      _keyInt = _key as Uint8List;
      keyBox!.put('key', _key);
    } else {
      //print("HIVE : key exists");
      _key = keyBox!.get('key');
      _keyInt = _key as Uint8List;
    }

    // open the encrypted box based on the key we put on the storage
    encryptedBox = await Hive.openBox(
      'vault',
      encryptionCipher: HiveAesCipher(_keyInt),
    );
    await encryptedBox!.compact();
  }

  static Future<void> putString(String key, String value) async {
    // check if null
    if(keyBox == null) {
      await init();
    }

    // not null, means we can put the data on the keyBox
    await keyBox!.put(key, value);
  }

  static Future<void> putStringList(String key, List<String> value) async {
    // check if null
    if(keyBox == null) {
      await init();
    }

    // not null, means we can put the data on the keyBox
    await keyBox!.put(key, value);
  }

  static String? getString(String key) {
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

  static List<String>? getStringList(String key) {
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

  static Future<void> putBool(String key, bool value) async {
    // check if null
    if(keyBox == null) {
      init();
    }

    await keyBox!.put(key, value);
  }

  static bool getBool(String key) {
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

  static List<String> getKeys(String key) {
    List<String> _result = [];
    String _key = "";
    var _keys = keyBox!.keys;
    if(_keys.length > 0) {
      _keys.forEach((_keyDynamic) {
        _key = _keyDynamic.toString();
        if(_key.contains(key)) {
          _result.add(_key);
        }
      });
    }
    return _result;
  }

  static Future<void> clear() async {
    if(keyBox != null) {
      // clear the keyBox
      var keys = keyBox!.keys;
      keys.forEach((key) {
        // skip the "key" as this is hold the encryption key for our encryptedBox
        // if we removed the key, it will got error during logon as we cannot re-open the
        // encrypted box and need to recreate it.
        if(key.toString().toLowerCase() != "key") {
          keyBox!.delete(key);
        }
      });
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

  static Future<void> delete(String key, [bool? exact]) async {
    bool _exact = (exact ?? false);

    if(_exact) {
      // check if got key on the key box or not?
      if(keyBox!.containsKey(key)) {
        // can be deleted
        keyBox!.delete(key);
      }
    }
    else {
      // get all the keys and find if the key string is on the key or not?
      var _keys = keyBox!.keys;
      _keys.forEach((keyDynamic) {
        String key = keyDynamic.toString();
        if(key.contains(key)) {
          // delete this data
          keyBox!.delete(key);
        }
      });
    }
  }
}