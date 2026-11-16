import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pinput/pinput.dart';

import '../../core/AuthService/AuthServiceProvider.dart';
import '../../core/Utils/device_id.dart';
import '../../core/Utils/pretty.dio.dart';
import '../../state/app_scope.dart';
import '../../state/app_state.dart';
import '../../ui/shell.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';

ScreenView loginScreen(BuildContext context, AppState s) => ScreenView([
  const Hd(''),
  Display('Welcome back', margin: const EdgeInsets.only(top: 20, bottom: 8)),
  const Muted(
    'Sign in with the mobile number registered with Vishal Optical.',
    small: false,
    margin: EdgeInsets.only(bottom: 22),
  ),
  LoginForm(s: s),
], foot: LoginFooterButton(s: s));

Future<void> _handleVerifyOtp(
  BuildContext context,
  WidgetRef ref,
  AppState s,
) async {
  final mobile = s.loginMobile.trim().replaceAll(RegExp(r'\s+'), '');
  final otp = s.loginCode.trim();

  if (otp.isEmpty) {
    s.toast('Please enter the OTP');
    return;
  }
  if (otp.length < 6) {
    s.toast('Please enter the complete 6-digit OTP');
    return;
  }

  s.showLoader('Verifying code...', null);
  try {
    final deviceId = await DeviceHelper.getDeviceId();
    final deviceName = await DeviceHelper.getDeviceName();
    final platform = DeviceHelper.getPlatform();

    final service = ref.read(authServiceProvider);
    final res = await service.verifyOtpData(
      phone: mobile,
      otp: otp,
      deviceId: deviceId,
      deviceName: deviceName,
      platform: platform,
    );

    s.hideLoader();

    if (res.code == 0 || res.error == false) {
      final token = res.data?.token;
      if (token != null && token.toString().trim().isNotEmpty) {
        if (Hive.isBoxOpen('userdata')) {
          await Hive.box('userdata').put('token', token);
        } else {
          final box = await Hive.openBox('userdata');
          await box.put('token', token);
        }
        s.store.setString('asl.token', token.toString());
        log('Token saved successfully in Hive: $token');
      }
      s.toast(res.message ?? 'Logged in successfully');
      s.hist = [];
      s.go('home', push: false);
    } else {
      _LoginFormState.activeState?.clearOtp();
      s.toast(res.message ?? 'Invalid or expired OTP.');
    }
  } catch (e) {
    s.hideLoader();
    _LoginFormState.activeState?.clearOtp();
    if (e is DioException) {
      s.toast(getDioErrorMessage(e));
    } else {
      s.toast(e.toString());
    }
  }
}

class LoginFooterButton extends ConsumerWidget {
  final AppState s;
  const LoginFooterButton({super.key, required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!s.loginOtpSent) {
      return Btn('Send OTP', onTap: () => _handleSendOtp(context, ref));
    }
    return Btn('Continue', onTap: () => _handleVerifyOtp(context, ref, s));
  }

  Future<void> _handleSendOtp(BuildContext context, WidgetRef ref) async {
    final mobile = s.loginMobile.trim().replaceAll(RegExp(r'\s+'), '');
    if (mobile.isEmpty) {
      s.toast('Please enter your mobile number');
      return;
    }
    if (mobile.length < 10) {
      s.toast('Please enter a valid 10-digit mobile number');
      return;
    }

    s.showLoader('Sending OTP...', null);
    try {
      final deviceId = await DeviceHelper.getDeviceId();
      final service = ref.read(authServiceProvider);
      final res = await service.sendOTP(phone: mobile, deviceId: deviceId);
      s.hideLoader();
      if (res.code == 0 || res.error == false) {
        s.loginCode = '';
        s.setLoginOtpSent(true);
        s.toast(res.message ?? 'OTP sent successfully');
      } else {
        s.toast(res.message ?? 'Failed to send OTP');
      }
    } catch (e) {
      s.hideLoader();
      if (e is DioException) {
        s.toast(getDioErrorMessage(e));
      } else {
        s.toast(e.toString());
      }
    }
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  final AppState? s;
  const LoginScreen({super.key, this.s});

  static ScreenView view(BuildContext context, AppState s) =>
      loginScreen(context, s);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final state = widget.s ?? AppScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Hd(''),
        Display(
          'Welcome back',
          margin: const EdgeInsets.only(top: 20, bottom: 8),
        ),
        const Muted(
          'Sign in with the mobile number registered with Vishal Optical.',
          small: false,
          margin: EdgeInsets.only(bottom: 22),
        ),
        LoginForm(s: state),
      ],
    );
  }
}

class LoginForm extends ConsumerStatefulWidget {
  final AppState s;
  const LoginForm({super.key, required this.s});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  static _LoginFormState? activeState;
  late final TextEditingController mobile;
  late final TextEditingController otpController;
  final FocusNode otpFocusNode = FocusNode();

  void clearOtp() {
    otpController.clear();
    widget.s.loginCode = '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        otpFocusNode.requestFocus();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    activeState = this;
    mobile = TextEditingController(text: widget.s.loginMobile);
    otpController = TextEditingController(text: widget.s.loginCode);
    mobile.addListener(_sync);
    otpController.addListener(_sync);
  }

  void _sync() {
    widget.s.loginMobile = mobile.text;
    widget.s.loginCode = otpController.text;
  }

  @override
  void didUpdateWidget(LoginForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (mobile.text != widget.s.loginMobile) {
      mobile.text = widget.s.loginMobile;
    }
    if (otpController.text != widget.s.loginCode) {
      otpController.text = widget.s.loginCode;
    }
    if (!oldWidget.s.loginOtpSent && widget.s.loginOtpSent) {
      otpController.clear();
      widget.s.loginCode = '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        otpFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    if (activeState == this) {
      activeState = null;
    }
    mobile.removeListener(_sync);
    otpController.removeListener(_sync);
    mobile.dispose();
    otpController.dispose();
    otpFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isOtpSent = widget.s.loginOtpSent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            eyebrow(context, 'Mobile number'),
            if (isOtpSent)
              GestureDetector(
                onTap: () {
                  otpController.clear();
                  widget.s.loginCode = '';
                  widget.s.setLoginOtpSent(false);
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.navy,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        FieldBox(
          hint: 'Enter Your Mobile Number',
          controller: mobile,
          keyboard: TextInputType.phone,
          label: 'Mobile number',
          enabled: !isOtpSent,
          readOnly: isOtpSent,
          onChanged: (_) => _sync(),
          style: TextStyle(fontSize: 14, color: c.ink, fontFeatures: kTabular),
        ),
        if (isOtpSent) ...[
          const SizedBox(height: 18),
          eyebrow(context, 'One-time code'),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final boxWidth =
                  ((constraints.maxWidth - 40) / 6).floorToDouble();
              final defaultPinTheme = PinTheme(
                width: boxWidth,
                height: 52,
                textStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                  fontFeatures: kTabular,
                ),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.line),
                ),
              );

              final focusedPinTheme = defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: c.ink, width: 1.5),
                ),
              );

              return Pinput(
                length: 6,
                controller: otpController,
                focusNode: otpFocusNode,
                keyboardType: TextInputType.number,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: defaultPinTheme,
                separatorBuilder: (index) => const SizedBox(width: 8),
                onChanged: (_) => _sync(),
                onCompleted: (_) {
                  _sync();
                  _handleVerifyOtp(context, ref, widget.s);
                },
              );
            },
          ),
          const SizedBox(height: 10),
          const Muted(
            'Code sent by SMS. Accounts and staff logins are created by Vishal Optical; there is no sign-up.',
          ),
        ],
      ],
    );
  }
}

