import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';

@immutable
abstract class ProfileEvent extends Equatable {
  ProfileEvent([List props = const <dynamic>[]]);
}

class Save extends ProfileEvent {
  final String id, phoneNumber;
  Save({this.id, this.phoneNumber});
  @override
  String toString() => 'Save';

  @override
  List<Object> get props => [id, phoneNumber];
}

class Verify extends ProfileEvent {
  final String id, phoneNumber;
  final PhoneVerificationCompleted verificationCompleted;
  final PhoneVerificationFailed verificationFailed;
  final PhoneCodeSent codeSent;

  Verify(
      {this.id,
      this.phoneNumber,
      this.verificationCompleted,
      this.verificationFailed,
      this.codeSent});
  @override
  String toString() => 'Verify';

  @override
  List<Object> get props =>
      [id, phoneNumber, verificationCompleted, verificationFailed, codeSent];
}

class ConfirmOTP extends ProfileEvent {
  final String smsCode, verificationID, id, phoneNumber;
  ConfirmOTP({this.smsCode, this.verificationID, this.id, this.phoneNumber});
  @override
  String toString() => 'ConfirmOTP';

  @override
  List<Object> get props => [smsCode, verificationID, id, phoneNumber];
}

class VerifyConfirm extends ProfileEvent {
  @override
  String toString() => 'VerifyConfirm';

  @override
  List<Object> get props => [];
}

class VerifyFailed extends ProfileEvent {
  @override
  String toString() => 'VerifyFailed';

  @override
  List<Object> get props => [];
}

class CodeSend extends ProfileEvent {
  final String verificationID;
  CodeSend({this.verificationID});
  @override
  String toString() => 'CodeSend';

  @override
  List<Object> get props => [verificationID];
}
