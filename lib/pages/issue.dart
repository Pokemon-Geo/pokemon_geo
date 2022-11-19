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
  final int scale;

  const IssuePage(this.issue, this.scale, {Key? key}) : super(key: key);

  @override
  State<IssuePage> createState() => _IssuePageState();
}

class _IssuePageState extends State<IssuePage> {
  final ImagePicker _picker = ImagePicker();
  Phase phase = Phase.noPhoto;
  late String category;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<API>(context, listen: false);
    return WillPopScope(
      onWillPop: () async {
        api.fetchIssues();
        api.fetchScore();
        return true;
      },
      child: Scaffold(
          body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            "Solve the issue",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -pi,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 50,
            child: FutureBuilder(
                future: api.getImageUrl(widget.issue.imageId),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Image.network(snapshot.data!);
                  } else if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
                  }
                  return SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 320,
                      child: const CircularProgressIndicator());
                }),
          ),
          Text(
            phase == Phase.finished || phase == Phase.canVote
                ? "You got ${widget.issue.points} points!"
                : "Solve this issue and get ${widget.issue.points} points!",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          ...action(api)
        ],
      )),
    );
  }

  List<Widget> action(API api) {
    var finishButton = ElevatedButton(
        onPressed: () {
          api.fetchIssues();
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
                category = await api.postPhoto(
                    widget.issue.issueId, photo, widget.scale);
                setState(() {
                  _confettiController.play();
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
            "You have earned the privilege to vote. Our AI thinks this is $category. What do you think?",
            textAlign: TextAlign.center,
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            ElevatedButton(
                onPressed: () async {
                  await api.vote(widget.issue.issueId, true);
                  setState(() {
                    _confettiController.play();
                    phase = Phase.finished;
                  });
                },
                child: const Text("Primary")),
            ElevatedButton(
                onPressed: () async {
                  await api.vote(widget.issue.issueId, false);
                  setState(() {
                    _confettiController.play();
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
