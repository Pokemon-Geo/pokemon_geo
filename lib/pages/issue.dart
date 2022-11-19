import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pokemon_geo/utils.dart';
import 'package:provider/provider.dart';

import '../api.dart';

enum Phase { noPhoto, uploading, canVote, finished }

class IssuePage extends StatefulWidget {
  final Issue issue;

  const IssuePage(this.issue, {Key? key}) : super(key: key);

  @override
  State<IssuePage> createState() => _IssuePageState();
}

class _IssuePageState extends State<IssuePage> {
  final ImagePicker _picker = ImagePicker();
  Phase phase = Phase.noPhoto;
  late String category;
  late ConfettiController _controllerCenter;

  @override
  void initState() {
    super.initState();
    _controllerCenter =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _controllerCenter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<API>(context, listen: false);
    return Scaffold(
        body: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(
          "Solve the issue",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        ConfettiWidget(
          confettiController: _controllerCenter,
          blastDirection: pi,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 50,
        ),
        Text(
          phase == Phase.finished || phase == Phase.canVote
              ? "You got ${widget.issue.points} points!"
              : "Solve this issue and get ${widget.issue.points} points!",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        FutureBuilder(
            future: api.getImageUrl(widget.issue.imageId),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Image.network(snapshot.data!);
              } else if (snapshot.hasError) {
                return Text(snapshot.error.toString());
              }
              return const Center(child: CircularProgressIndicator());
            }),
        ...action(api)
      ],
    ));
  }

  List<Widget> action(API api) {
    var finishButton = ElevatedButton(
        onPressed: () {
          api.fetchScore();
          Navigator.pop(context);
        },
        child: const Text("Finished"));
    switch (phase) {
      case Phase.noPhoto:
        return [
          ElevatedButton(
              onPressed: () async {
                final XFile? photo =
                    await _picker.pickImage(source: ImageSource.camera);
                if (photo == null) return;
                setState(() {
                  phase = Phase.uploading;
                });
                category = await api.postPhoto(widget.issue.issueId, photo);
                setState(() {
                  _controllerCenter.play();
                  phase = Utils.canVote(api.totalXP)
                      ? Phase.canVote
                      : Phase.finished;
                });
              },
              child: const Text("Take picture"))
        ];
      case Phase.canVote:
        return [
          Text(
              "You have earned the privilege to vote. Our AI thinks this is $category. What do you think?"),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            ElevatedButton(
                onPressed: () async {
                  await api.vote(widget.issue.issueId, true);
                  setState(() {
                    _controllerCenter.play();
                    phase = Phase.finished;
                  });
                },
                child: const Text("Primary")),
            ElevatedButton(
                onPressed: () async {
                  await api.vote(widget.issue.issueId, false);
                  setState(() {
                    _controllerCenter.play();
                    phase = Phase.finished;
                  });
                },
                child: const Text("Footway"))
          ]),
          finishButton
        ];
      case Phase.finished:
        return [finishButton];
      case Phase.uploading:
      default:
        return [const Center(child: CircularProgressIndicator())];
    }
  }
}
