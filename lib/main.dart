import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

void main() {
  setUrlStrategy(PathUrlStrategy());
  OpenAI.apiKey = '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';
  OpenAI.organization = "org-eVzEtAqe0w8qEUavocje4Sqj";
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guru GPT',
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Guru GPT'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  final controller = TextEditingController();

  List<String> respostas = [];
  bool isLoading = false;

  List<Uint8List> images = [];
  late final tabController = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Banner(
      message: 'Baguncinha',
      location: BannerLocation.topEnd,
      color: Colors.purple,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          bottom: TabBar(
            controller: tabController,
            tabs: <Widget>[
              Tab(
                icon: Icon(Icons.text_rotation_angleup_sharp),
              ),
              Tab(
                icon: Icon(Icons.image_outlined),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text('Gerar Texto'),
                        Expanded(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: respostas.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              return SelectableText(
                                respostas[index],
                                style: Theme.of(context).textTheme.bodyLarge,
                              );
                            },
                          ),
                        ),
                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 60, vertical: 60),
                            child: CircularProgressIndicator(),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text('Gerar Imagem'),
                        Expanded(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: images.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              return Image.memory(
                                images[index],
                              );
                            },
                          ),
                        ),
                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 60, vertical: 60),
                            child: CircularProgressIndicator(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: tabController.index == 0
            ? Padding(
                padding: const EdgeInsets.fromLTRB(60, 30, 60, 60),
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => generateTextAI(),
                  decoration: InputDecoration(
                    hintText: 'Digite a sua pergunta ao Guru...',
                    suffixIconColor: Colors.black,
                    suffix: IconButton(
                      icon: const Icon(
                        Icons.send,
                      ),
                      onPressed: () async => await generateTextAI(),
                    ),
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(60, 30, 60, 60),
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => generateImageAI(),
                  decoration: InputDecoration(
                    hintText: 'Qual imagem você quer gerar que o Guru desenhe?',
                    suffixIconColor: Colors.black,
                    suffix: IconButton(
                      icon: const Icon(
                        Icons.send,
                      ),
                      onPressed: () async => await generateImageAI(),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> generateImageAI() async {
    if (isLoading || controller.text.length < 2) return;
    final text = controller.text;
    controller.text = '';

    setState(() {
      isLoading = true;
    });
    final chatCompletion = await OpenAI.instance.image.create(
      prompt: text,
      responseFormat: OpenAIImageResponseFormat.b64Json,
    );
    setState(() {
      images.add(base64Decode(chatCompletion.data.first.data ?? ''));
      isLoading = false;
    });
  }

  Image imageFromBase64String(String base64String) {
    return Image.memory(base64Decode(base64String));
  }

  Future<void> generateTextAI() async {
    if (isLoading || controller.text.length < 2) return;
    final text = controller.text;
    controller.text = '';

    setState(() {
      isLoading = true;
    });
    OpenAIChatCompletionModel chatCompletion = await OpenAI.instance.chat.create(
      model: "gpt-3.5-turbo-16k",
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: text,
          role: OpenAIChatMessageRole.user,
        ),
      ],
    );
    setState(() {
      respostas.add(chatCompletion.choices.first.message.content);
      isLoading = false;
    });
  }
}
