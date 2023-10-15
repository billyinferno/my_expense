import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/user_api.dart';
import 'package:my_expense/model/error_model.dart';
import 'package:my_expense/model/users_me_model.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/misc/error_parser.dart';
import 'package:my_expense/utils/misc/show_loader_dialog.dart';
import 'package:my_expense/utils/misc/snack_bar.dart';
import 'package:my_expense/utils/prefs/shared_user.dart';

class UserChangePassword extends StatefulWidget {
  const UserChangePassword({Key? key}) : super(key: key);

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
        title: Center(child: Text("Change Password")),
        leading: IconButton(
          onPressed: () {
            Navigator.maybePop(context, false);
          },
          icon: Icon(
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
                              icon: Icon(Ionicons.lock_closed_outline),
                              border: UnderlineInputBorder(
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
                          SizedBox(height: 10,),
                          TextFormField(
                            controller: _newPassword,
                            decoration: InputDecoration(
                              labelText: "New Password",
                              icon: Icon(Ionicons.lock_closed_outline),
                              border: UnderlineInputBorder(
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
                          SizedBox(height: 10,),
                          TextFormField(
                            controller: _retypeNewPassword,
                            decoration: InputDecoration(
                              labelText: "Retype New Password",
                              icon: Icon(Ionicons.lock_closed_outline),
                              border: UnderlineInputBorder(
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
                      padding: EdgeInsets.all(10),
                      child: MaterialButton(
                        minWidth: double.infinity,
                        onPressed: (() {
                          _updatePassword().then((value) {
                            // showed that we already success update the password
                            ScaffoldMessenger.of(context).showSnackBar(
                              createSnackBar(
                                message: "Password updated",
                                icon: Icon(
                                  Ionicons.checkmark_circle,
                                  size: 20,
                                  color: accentColors[0],
                                ),
                              )
                            );
                          }).onError((error, stackTrace) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              createSnackBar(
                                message: error.toString(),
                              )
                            );
                          });
                        }),
                        child: Text("Change Password"),
                        color: accentColors[0],
                        height: 50,
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
    String _strCurrentPassword = _currentPassword.text;
    String _strNewPassword = _newPassword.text;
    String _strRetypeNewPassword = _retypeNewPassword.text;

    if( _strCurrentPassword.trim().length > 0 &&
        _strNewPassword.trim().length > 0 &&
        _strRetypeNewPassword.trim().length > 0 ) {
      // got data, now check if the newPassword and the retypeNewPasssword is
      // the same value or not?
      if(_strNewPassword == _strRetypeNewPassword) {
        // new password match, now call the api for updating the password.
        // before that we should show the loader
        showLoaderDialog(context);

        await _userHttp.updatePassword(_userMe.username, _strCurrentPassword, _strNewPassword).then((_) {
          // all finished, pop the loader
          Navigator.pop(context);
        }).onError((error, stackTrace) {
          debugPrint(error.toString());
          Navigator.pop(context);
          ErrorModel _err = parseErrorMessage(error.toString());
          throw new Exception(_err.message);
        });
      }
      else {
        throw new Exception("New Password didn't match");
      }
    }
    else {
      throw new Exception("Please fill the missing fields information");
    }
  }
}