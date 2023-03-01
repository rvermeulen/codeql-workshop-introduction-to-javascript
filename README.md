# CodeQL workshop for JavaScript: Finding a prototype pollution vulnerability

This workshop is based on the workshop [codeql-js-goof-workshop](https://github.com/advanced-security/codeql-workshops-staging/tree/master/javascript/codeql-js-goof-workshop).

## Contents

- [CodeQL workshop for JavaScript: Finding a prototype pollution vulnerability](#codeql-workshop-for-javascript-finding-a-prototype-pollution-vulnerability)
  - [Contents](#contents)
  - [Prerequisites and setup instructions](#prerequisites-and-setup-instructions)
  - [Workshop](#workshop)
    - [Learnings](#learnings)
    - [Problem description](#problem-description)
    - [Exercises](#exercises)
      - [Exercise 1](#exercise-1)
      - [Exercise 2](#exercise-2)
      - [Exercise 3](#exercise-3)
      - [Exercise 4](#exercise-4)
      - [Exercise 5](#exercise-5)
      - [Exercise 6](#exercise-6)
      - [Exercise 7](#exercise-7)
      - [Exercise 8](#exercise-8)
      - [Exercise 9](#exercise-9)
      - [Exercise 10](#exercise-10)
      - [Exercise 11](#exercise-11)
      - [Exercise 12](#exercise-12)


## Prerequisites and setup instructions

- Install [Visual Studio Code](https://code.visualstudio.com/).
- Install the [CodeQL extension for Visual Studio Code](https://codeql.github.com/docs/codeql-for-visual-studio-code/setting-up-codeql-in-visual-studio-code/).
- Install the [latest](https://github.com/github/codeql-cli-binaries/releases/latest) CodeQL CLI and make it available on your [PATH](https://en.wikipedia.org/wiki/PATH_(variable)).
- Clone this repository recursively to ensure the submodule is cloned:
  
  ```bash
  git clone --recursive https://github.com/rvermeulen/codeql-workshop-javascript-prototype-pollution
  ```

- Install the CodeQL pack dependencies using the command `CodeQL: Install Pack Dependencies` and select `exercises`, and `solutions`.
- Build the database `nodejs-goof-db.zip` by running the command `make` or manually executed the commands associated with the `nodejs-goof-db.zip` Make target.
  Alternatively, you can download a [pre-built database](https://drive.google.com/file/d/1BPvRlCIVbX7Hwvd05Zk5cSOpB8Wa5JKs/view?usp=sharing).
- Select the database using the command `CodeQL: Choose Database from Archive` and pass the path to the database.

## Workshop

### Learnings

This workshop is an introduction to JavaScript and will cover:

- How to build a database for a JavaScript project.
- How QL represents JavaScript source-code.
- How to describe JavaScript program elements in QL.
- How to use QL classes to create reusable patterns.
- How to identify API calls to external functions using the API graph.
- How to use global data-flow to find flows from untrusted data to security sensitive operations.

### Problem description

In this workshop we will introduce QL for JavaScript by finding a JavaScript [prototype pollution](https://portswigger.net/web-security/prototype-pollution) vulnerability in a deliberately vulnerable
NodeJS application named [Goof](https://github.com/snyk-labs/nodejs-goof) by [Snyk Labs](https://github.com/snyk-labs).

Prototype pollution is a type of vulnerability in which an attacker is able to modify `Object.prototype`.
This can happen when recursively merging a user-controlled object with another object, allowing an attacker to modify the built-in Object prototype.
Once that is done, later requests can abuse the new property by abusing newly obtained privileges.

The _Goof_ application contains an example [exploit](nodejs-goof/exploits/prototype-pollution.sh) that exploits the vulnerability in the _Goof_ application.
The exploit abuses the `merge` of an user-controlled object in the Chat [add handler](./nodejs-goof/routes/index.js) (line 334) to gain the same privileges as an admin user.

```bash
 curl --request PUT \
      --url "$GOOF_HOST/chat" \
      --header 'content-type: application/json' \
      --data '{"auth": {"name": "user", "password": "pwd"}, "message": { "text": "😈", "__proto__": {"canDelete": true}}}'
```

The corresponding vulnerable `merge` call from the Chat [add handler](./nodejs-goof/routes/index.js).

```javascript
...
 _.merge(message, req.body.message, {
      id: lastId++,
      timestamp: Date.now(),
      userName: user.name,
    });
...
```

Key information for writing the query are:

1. The request is processed by the Chat [add handler](./nodejs-goof/routes/index.js).
2. Information from the request object containing user-controlled information is provide to the `merge` call.

### Exercises

Using the exercises we will incrementally build a final query to find the prototype pollution vulnerability.
In the first part we will identify the entry point that processes user-provided data.
Then we will identify the security sensitive `merge` call that can be abused by an attacker.
Finally, we will use global dataflow to connect the two by creating a configuration that determines if user-controlled data can reach the `merge` call.

#### Exercise 1

We will start with reasoning about the abstract syntax tree (AST) of our JavaScript program to identify all functions.

Implement [Exercises1.ql](exercises/Exercise1.ql) such that it finds all functions in the program.

<details>
<summary>Hints</summary>

- Use the autocompletion function to determine a useful QL call to describe functions.
- Alternatively, use the VS Code file explorer to open a file from the selected database and use the command `CodeQL: View Ast` to view the AST of the file to determine if there are useful QL classes to solve the question.

</details>

A solution can be found in the query [Exercise1.ql](solutions/Exercise1.ql).

#### Exercise 2

All the functions in the program is a good starting point.
However, we are interested in the function representing the `add` handler.

Implement [Exercises2.ql](exercises/Exercise2.ql) such that it finds all functions in the program with the name `add`.

<details>
<summary>Hints</summary>

- The class `Function` has a member predicate named `getName` that returns the name of the function.
- Use the formula [=](https://codeql.github.com/docs/ql-language-reference/formulas/#equality) to compare the name to `"add"`.

</details>

A solution can be found in the query [Exercise2.ql](solutions/Exercise2.ql).

#### Exercise 3

Looking at the results of the query that finds all functions names `add` shows that it finds a lot of unrelated functions.
To exclude the unrelated functions we need to add more constraints on the pattern described by our query.

Which characteristics of our target function can be used to distinguish it?
The signature, that is the parameters, might provide a solution.

Implement [Exercises3.ql](exercises/Exercise3.ql) such that it finds our Chat handler `add`.

<details>
<summary>Hints</summary>

- The class `Function` has a member predicate named `getNumParameter` that returns the number of parameters.
- The class `Function` has a member predicate named `getParameter` that returns a `Parameter` given an index.
- The class `Parameter` describes the formal parameters of a function and has a member predicate `getName` that returns its name.

</details>

A solution can be found in the query [Exercise3.ql](solutions/Exercise3.ql).

#### Exercise 4

We have now sufficiently described our `add` handler to successfully find it in the JavaScript program.
Recall that [predicates](https://codeql.github.com/docs/ql-language-reference/predicates/) and [classes](https://codeql.github.com/docs/ql-language-reference/types/#classes) allow you to encapsulate logical conditions in a reusable format.

Convert your solution to [Exercise3.ql](solutions/Exercise3.ql) into a _class_ in [Exercises4.ql](exercises/Exercise4.ql) by replacing the [none](https://codeql.github.com/docs/ql-language-reference/formulas/#none) formula in the [characteristic predicate](https://codeql.github.com/docs/ql-language-reference/types/#characteristic-predicates) of the `AddChatHandler` class.

A solution can be found in the query [Exercise4.ql](solutions/Exercise4.ql).

#### Exercise 5

Now that we found our `add` handler, we are going to look for the call to the `merge` function.

Implement [Exercises5.ql](exercises/Exercise5.ql) such that it finds all method calls in the program.

<details>
<summary>Hints</summary>

- Use the autocompletion function to determine a useful QL call to describe functions.
- Alternatively, use the VS Code file explorer to open a file from the selected database and use the command `CodeQL: View Ast` to view the AST of the file to determine if there are useful QL classes to solve the question.

</details>

A solution can be found in the query [Exercise5.ql](solutions/Exercise5.ql).

#### Exercise 6

The next step is to restrict all the method calls to calls that call the method `merge`.

Implement [Exercises6.ql](exercises/Exercise6.ql) such that it finds all method calls to the method `merge` in the program.

<details>
<summary>Hints</summary>

- The class `MethodCallExpr` has a member predicate `getCalleeName` that returns the name of the called method.
- Use the formula [=](https://codeql.github.com/docs/ql-language-reference/formulas/#equality) to compare the method name to `"merge"`.

</details>

A solution can be found in the query [Exercise6.ql](solutions/Exercise6.ql).

#### Exercise 7

Unlike looking for functions with the name `add`, our solution returns only a single result because this JavaScript program only has a single call to a `merge` method.
However, this is unlikely to be the case in real-world applications.

To improve the precision of our query we can look at the qualifier `_` of the method call.
Looking at the definition of `_` we can see that it points to the module `lodash`.

```javascript
var _ = require('lodash');
```

We will start by identifying the import of _Lodash_.
Implement [Exercises7.ql](exercises/Exercise7.ql) such that it finds all the imports of the module named `"lodash"`.

<details>
<summary>Hints</summary>

- Imported modules are represented by the class `ModuleImportNode` part of the `DataFlow` module.
- The `DataFlow` module provides the predicate `moduleImport` to reason about module imports by name.

</details>

A solution can be found in the query [Exercise7.ql](solutions/Exercise7.ql).

#### Exercise 8

With the import of the Lodash module, we need to identify calls to its member `merge`.

Implement [Exercises8.ql](exercises/Exercise8.ql) such that it finds all calls to member `merge` of the `"lodash"` module.

<details>
<summary>Hints</summary>

- The class `ModuleImportNode`, part of the `DataFlow` module, has a member predicate `getAMemberCall` to reason about member calls by name.

</details>

A solution can be found in the query [Exercise8.ql](solutions/Exercise8.ql).

#### Exercise 9

While the previous query is sufficiently precise in this case to find the member call to `merge` in the Lodash module, the question provides an opportunity to look at [API graphs](https://codeql.github.com/docs/codeql-language-guides/using-api-graphs-in-python/#using-api-graphs-in-python).
API graphs are a uniform interface for referring to functions, classes, and methods defined in _external libraries_ that was first added to our Python standard library (hence the link to the Python documentation).

The most common entry point into the API graph is the importing of an external package or module.
Using the predicate `moduleImport`, part of the `API` module, we can find those entry points.
For every node in the API graph, for which we can statically infer its name, we can reason about its attributes using the `getMember` predicate.

Complete [Exercises9.ql](exercises/Exercise9.ql) by implementing the predicate `lodash`, representing the Lodash module, and the class `LodashMergeCall`, to represent calls to its member `merge`, by using the API graph implemented by the `API` module.

<details>
<summary>Hints</summary>

- The `Node` class, part of the `API` module, has the member predicate `getACall` to reason about calls to the member.


</details>

A solution can be found in the query [Exercise9.ql](solutions/Exercise9.ql).

#### Exercise 10

With the `merge` calls identified we can start focussing on the vulnerability.
A user-provided value that is passed to the `merge` call can be exploited by an attacker.

Reuse the identification of the `merge` call from [Exercises9.ql](exercises/Exercise9.ql) and identify the arguments to the `merge` call in [Exercises10.ql](exercises/Exercise10.ql)

<details>
<summary>Hints</summary>

- The `CallNode` class, part of the `API` module, has the member predicate `getAnArgument` to reason about arguments passed to the call.

</details>

A solution can be found in the query [Exercise10.ql](solutions/Exercise10.ql).

#### Exercise 11

Having both identified the entry point and the security sensitive operation, we can move to reasoning about [dataflow](https://codeql.github.com/docs/codeql-language-guides/analyzing-data-flow-in-javascript-and-typescript/).
Up to now we have already used parts of the available data flow analysis due to the nature of dynamic languages when reasoning about imported modules and using the API graph.

The dataflow graph is built on top of the AST, but contains more detailed semantic information about the flow of information through the program.
This allows us to determine where user-controlled data is used an whether that use poses a security risk.

In this exercise we are going to make use of global dataflow analysis.
Global dataflow analysis can track the use of values across function/method boundaries.
This analysis is computational expensive operation and to make this tractable we have to restrict it the parts of the programs that are relevant.
This is done using a configuration pattern where we need to extend a dataflow or taintracking configuration and provide predicates to configure the analysis.

For this workshop it suffices to introduce the concepts `source` and `sink`.
The global dataflow analysis is configured by specifying the _sources_, the starting points of the analysis, that need to be considered, and the _sinks_, the program elements where the analysis stops and is considered complete.
With the _sources_ and _sinks_ defined, the global dataflow analysis will try to determine if there is a _sink_ that is reachable from a _source_.
In other words, does there exists a path from a _source_ to a _sink_.

Complete [Exercise11.ql](exercises/Exercise11.ql) by copying your solution from [Exercises4.ql](exercises/Exercise4.ql) and implement the `getRequestParameter` predicate.

Use _quick evaluation_ on the `isSource` member predicate of the `PrototypePollutionConfiguration` to validate that it finds the correct request parameter.

<details>
<summary>Hints</summary>

- The `CallNode` class, part of the `API` module, has the member predicate `getAnArgument` to reason about arguments passed to the call.

</details>

A solution can be found in the query [Exercise11.ql](solutions/Exercise11.ql).

#### Exercise 12

The last step is to specify the `sink` of the global dataflow configuration.

Reuse your solution for [Exercises10.ql](exercises/Exercise10.ql) and complete [Exercises10.ql](exercises/Exercise10.ql) by implementing the class `LodashMergeSink`.

Running the query should provide a dataflow path from the `req` parameter to an argument of the `merge` call.

A solution can be found in the query [Exercise11.ql](solutions/Exercise11.ql).
