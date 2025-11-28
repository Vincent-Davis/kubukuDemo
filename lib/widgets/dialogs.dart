

import 'package:flutter/material.dart';
// import 'package:get/get.dart';

class ConfirmationDialog extends StatefulWidget {
  final String? title;
  final String? content;
  final String textConfirm;
  final String textCancel;
  final Function? onConfirm;
  final Function? onCancel;

  const ConfirmationDialog(
      {super.key,
        this.title,
        this.content,
        this.textConfirm = "Ya",
        this.textCancel = "Batal",
        this.onConfirm,
        this.onCancel});

  @override
  _ConfirmationDialogState createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      child: dialogContent(context),
    );
  }

  Container dialogContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.title!,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500),
          ),
          const SizedBox(
            height: 24,
          ),
          widget.content != ""
              ? Text(widget.content!, style: const TextStyle(fontSize: 15))
              : Container(),
          widget.content != ""
              ? const SizedBox(
            height: 24,
          )
              : Container(),
          Row(
            children: [
              Flexible(
                flex: 1,
                child: TextButton(
                  onPressed: () {
                    // Get.back();
                    widget.onConfirm!();
                  }, child: Text(widget.textConfirm),
                ),
                /*child: RoundedButton(
                  context: Get.context!,
                  onTap: () {
                    Get.back();
                    widget.onConfirm!();
                  },
                  status: Status.ACTIVE,
                  padding: 10,
                  radius: 20,
                  margin: EdgeInsets.zero,
                  text: widget.textConfirm,
                ),*/
              ),
            ],
          )
        ],
      ),
    );
  }
}