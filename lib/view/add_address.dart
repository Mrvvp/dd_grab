import 'package:dd_grab/models/address_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../viewmodels/address_vm.dart';

class AddressFormPage extends ConsumerStatefulWidget {
  final Address? address;

  const AddressFormPage({super.key, this.address});

  @override
  ConsumerState<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends ConsumerState<AddressFormPage> {
  final Map<String, TextEditingController> _controllers = {};
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(addressViewModelProvider.notifier);
      notifier.initializeForm(widget.address);

      final formData = ref.read(addressFormProvider);
      formData.forEach((key, value) {
        _controllers[key] = TextEditingController(text: value);
      });
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 14,
    );
  }

  @override
  Widget build(BuildContext context) {
    final formData = ref.watch(addressFormProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade600,
        surfaceTintColor: Colors.yellow.shade600,

        title: Text(widget.address != null ? 'Edit Address' : 'Add Address'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          child: ListView(
            children: [
              ...formData.keys.map((key) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: _controllers[key],
                    decoration: InputDecoration(
                      labelText: key.replaceAll('_', ' ').toUpperCase(),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      ref
                          .read(addressViewModelProvider.notifier)
                          .updateFormField(key, value);
                    },
                  ),
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final errorMsg = await ref
                      .read(addressViewModelProvider.notifier)
                      .validateAndSave(widget.address?.id);
                  if (errorMsg != null) {
                    showToast(errorMsg);
                  } else {
                    Navigator.pop(context, true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  widget.address != null ? 'Update Address' : 'Save Address',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
