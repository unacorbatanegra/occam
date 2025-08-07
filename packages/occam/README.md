<!-- 
<p>
<a href="https://github.com/rrousselGit/riverpod/actions"><img src="https://github.com/rrousselGit/riverpod/workflows/Build/badge.svg" alt="Build Status"></a>
</p> -->

# Occam

Simple state manager based on native fluter stateful for my personal use.

Credits to: @roipeker

## Index

- [Why another state manager?](#why)
- [State Manager](#state-manager)
- [Rx Types](#rx-types)


## Why

When I started coding Flutter there were a lots of state managers and was hard to choose between them because I like some features of each of one.

Also as a package get bigger there's a lot of unnused code or features that become part of a project unnecesarily, so the result is a project with a lot of pieces of code recreating the wheel.

The purpose of this package is to be as simple as posible and provide an easy and safety way to developers create his applications quickily and also easily maintanable by providing only one way to handle:

* View
* Controller

The premisse is to have 

    1 view = 1 controller

View have only widgets withouth logic unless is a UI logic
and controllers have no widgets.

The result is a clean UI file and a clean logic file.

The `RxTypes` are a refactor that follows the GetX pattern to create reactives types, but without the `Obs` widget.
`Obs` widget made usafe dispose correctly rx types sinces there's not a explicit declaration and remove over the listeners attached to a `RxType`.

> This package is for my personal use and it could change the API over the time.



## Usage

```dart 
class HomePage extends StateWidget<HomeController> {
  const HomePage({Key? key}) : super(key: key);
  /// You can override this and pass your own providers
  @override
  HomeController createState() => HomeController();

  @override
  Widget build(BuildContext context) {
       return Scaffold(
      appBar: AppBar(
        title: const Text('Occam Demo'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: state.onButton,
        child: const Icon(Icons.add),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RxWidget<int>(
            notifier: state.counter,
            builder: (ctx, v) => Text('reactive $v'),
          ),
          RxWidget<Model>(
            notifier: state.model,
            builder: (ctx, v) => Text('reactive $v'),
          ),
          Center(
            child: ElevatedButton(
              onPressed: state.toSecondPage,
              child: const Text('To Second page'),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: state.toBottom,
              child: const Text('To Bottom'),
            ),
          ),
        ],
      ),
    );
  }
}
class HomeController extends StateController{

    final counter=1.rx;

    @override
    void initState() {
        //Executed when the widget is mounted
        super.initState();
    }
    @override
    void readyState() async {
        /// Is executed after the widget is mounted but with context safe,
        /// Here you can safely call:
        final arguments =ModalRoute.of(context)?.settings.arguments;
    }
    void onButton() {
        counter.value++;
    }
    void toSecondPage() async {
        final result = await navigator.pushNamed(
        '/secondPage',
        arguments: 'test arguments',
        );
    }
    @override
    void dispose() {
        counter.dispose();
        super.dispose();
    }
  }    
}

```
