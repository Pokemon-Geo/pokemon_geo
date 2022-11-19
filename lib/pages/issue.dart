import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class IssuePage extends StatefulWidget {
  final int id;

  const IssuePage(this.id, {Key? key}) : super(key: key);

  @override
  State<IssuePage> createState() => _IssuePageState();
}

class _IssuePageState extends State<IssuePage> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Solve the issue"),
        Image.network("https://graph.mapillary.com/:${widget.id}",
            headers: const {
              HttpHeaders.authorizationHeader:
                  'OAuth MLY|6267347309961156|ec0c7ce7dee135a998e9c786c224caf1'
            }),
        TextButton(
          onPressed: () async {
            final XFile? photo =
                await _picker.pickImage(source: ImageSource.camera);
            Navigator.pop(context, photo);
          },
          child: const Text("Take picture"),
        ),
      ],
    );
  }
}
