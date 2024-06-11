import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/user_api.dart';
import 'package:my_expense/model/error_model.dart';
import 'package:my_expense/model/users_me_model.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/misc/error_parser.dart';
import 'package:my_expense/utils/misc/show_dialog.dart';
import 'package:my_expense/utils/misc/show_loader_dialog.dart';
import 'package:my_expense/utils/prefs/shared_user.dart';

class UserChangePassword extends StatefulWidget {
  const UserChangePassword({super.key});

  @override
  State<UserChangePassword> createState() => _UserChangePasswordState();
}

class _UserChangePasswordState extends State<UserChangePassword> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final UserHTTPService _userHttp = UserHTTPService();
  final TextEditingController _currentPassword = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _retypeNewPassword = TextEditingController();

  late UsersMeModel _userMe;

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showRetypeNewPassword = false;

  @override
  void initState() {
    _showCurrentPassword = false;
    _showNewPassword = false;
    _showRetypeNewPassword = false;

    _userMe = UserSharedPreferences.getUserMe();

    super.initState();
  }

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _retypeNewPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Change Password")),
        leading: IconButton(
          onPressed: () {
            Navigator.maybePop(context, false);
          },
          icon: const Icon(
            Ionicons.close,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      color: secondaryDark,
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          TextFormField(
                            controller: _currentPassword,
                            decoration: InputDecoration(
                              labelText: "Current Password",
                              icon: const Icon(Ionicons.lock_closed_outline),
                              border: const UnderlineInputBorder(
                                borderSide: BorderSide(color: secondaryBackground, width: 1.0),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  (_showCurrentPassword ? Ionicons.eye_off_outline : Ionicons.eye_off_outline),
                                  color: secondaryLight,
                                ),
                                onPressed: (() {
                                  setState(() {
                                    _showCurrentPassword = !_showCurrentPassword;
                                  });
                                }),
                              ),
                            ),
                            obscureText: (!_showCurrentPassword),

                          ),
                          const SizedBox(height: 10,),
                          TextFormField(
                            controller: _newPassword,
                            decoration: InputDecoration(
                              labelText: "New Password",
                              icon: const Icon(Ionicons.lock_closed_outline),
                              border: const UnderlineInputBorder(
                                borderSide: BorderSide(color: secondaryBackground, width: 1.0),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  (_showNewPassword ? Ionicons.eye_off_outline : Ionicons.eye_off_outline),
                                  color: secondaryLight,
                                ),
                                onPressed: (() {
                                  setState(() {
                                    _showNewPassword = !_showNewPassword;
                                  });
                                }),
                              ),
                            ),
                            obscureText: (!_showNewPassword),
                          ),
                          const SizedBox(height: 10,),
                          TextFormField(
                            controller: _retypeNewPassword,
                            decoration: InputDecoration(
                              labelText: "Retype New Password",
                              icon: const Icon(Ionicons.lock_closed_outline),
                              border: const UnderlineInputBorder(
                                borderSide: BorderSide(color: secondaryBackground, width: 1.0),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  (_showRetypeNewPassword ? Ionicons.eye_off_outline : Ionicons.eye_off_outline),
                                  color: secondaryLight,
                                ),
                                onPressed: (() {
                                  setState(() {
                                    _showRetypeNewPassword = !_showRetypeNewPassword;
                                  });
                                }),
                              ),
                            ),
                            obscureText: (!_showRetypeNewPassword),

                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      child: MaterialButton(
                        minWidth: double.infinity,
                        onPressed: (() async {
                          await _updatePassword().then((value) async {
                            if (context.mounted) {
                              // showed that we already success update the password
                              await ShowMyDialog(
                                cancelEnabled: false,
                                confirmText: "OK",
                                confirmColor: accentColors[0],
                                dialogTitle: "Updated",
                                dialogText: "Password update successfully."
                              ).show(context);
                            }
                          }).onError((error, stackTrace) async {
                            // print the error
                            debugPrint("Error: ${error.toString()}");
                            debugPrintStack(stackTrace: stackTrace);

                            if (context.mounted) {
                              // show the error dialog
                              await ShowMyDialog(
                                cancelEnabled: false,
                                confirmText: "OK",
                                dialogTitle: "Error Update",
                                dialogText: "Error when update password."
                              ).show(context);
                            }
                          });
                        }),
                        color: accentColors[0],
                        height: 50,
                        child: const Text("Change Password"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _updatePassword() async {
    // check if all is already filled or not?
    String strCurrentPassword = _currentPassword.text;
    String strNewPassword = _newPassword.text;
    String strRetypeNewPassword = _retypeNewPassword.text;

    if( strCurrentPassword.trim().isNotEmpty &&
        strNewPassword.trim().isNotEmpty &&
        strRetypeNewPassword.trim().isNotEmpty ) {
      // got data, now check if the newPassword and the retypeNewPasssword is
      // the same value or not?
      if(strNewPassword == strRetypeNewPassword) {
        // new password match, now call the api for updating the password.
        // before that we should show the loader
        showLoaderDialog(context);

        await _userHttp.updatePassword(_userMe.username, strCurrentPassword, strNewPassword).onError((error, stackTrace) {
          debugPrint(error.toString());
          debugPrintStack(stackTrace: stackTrace);
          
          ErrorModel err = parseErrorMessage(error.toString());
          throw Exception(err.message);
        }).whenComplete(() {
          if (mounted) {
            // all finished, pop the loader
            Navigator.pop(context);
          }
        });
      }
      else {
        throw Exception("New Password didn't match");
      }
    }
    else {
      throw Exception("Please fill the missing fields information");
    }
  }
}