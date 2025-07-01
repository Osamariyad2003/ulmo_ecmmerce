
abstract class LoginEvent{}

class signInWithEmailAndPasswordEvent extends LoginEvent{
  String email;
  String password;
  signInWithEmailAndPasswordEvent(this.email,this.password);
}

class signInGoogleEvent extends LoginEvent{

}

class TogglePasswordEvent extends LoginEvent {
  final bool isPassword;

  TogglePasswordEvent(this.isPassword);
}
