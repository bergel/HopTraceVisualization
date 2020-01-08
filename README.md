# HopTraceVisualization

Load Roassal:
```Smalltalk
Metacello new
  baseline: 'Roassal2';
  repository: 'gitlocal:///Users/alexandrebergel/Dropbox/GitRepos/Roassal2' ;
  lock;
  load.
```

Load NeoJSON:
```Smalltalk
Metacello new
  repository: 'github://svenvc/NeoJSON/repository';
  baseline: 'NeoJSON';
  load.
```  
