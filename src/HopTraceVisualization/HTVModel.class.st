Class {
	#name : #HTVModel,
	#superclass : #Object,
	#instVars : [
		'functionCalls',
		'functionDefinitions'
	],
	#category : #HopTraceVisualization
}

{ #category : #'private - parsing trace' }
HTVModel >> bindCallsToFunctions [
	| fromFunction toFunction |
	functionCalls do: [ :c |
		fromFunction := self functionDefAtChar: c positionStart.
		toFunction := self functionDefAtChar: c targetChar.
		fromFunction addOutgoingFunction: toFunction.
		toFunction addIncomingFunction: fromFunction.
		fromFunction addOutgoingCall: c.
		toFunction addIncomingCall: c ]
	
]

{ #category : #'private - parsing trace' }
HTVModel >> functionDefAtChar: aCharIndex [
	"Use the symbol table to look up the function at a given char"
	| selectedFunctionDef offsetFromBegining |
	selectedFunctionDef := functionDefinitions first.
	offsetFromBegining := aCharIndex - selectedFunctionDef positionStart.
	functionDefinitions do: [ :f |
		((f positionStart <= aCharIndex) and: [ offsetFromBegining > (aCharIndex - f positionStart) ]) 
			ifTrue: [ selectedFunctionDef := f.
						 offsetFromBegining := aCharIndex - f positionStart ]
		 ].
	^ selectedFunctionDef
]

{ #category : #visualization }
HTVModel >> gtInspectorViewIn: composite [
	<gtInspectorPresentationOrder: -10>
	composite roassal2
		title: 'View';
		initializeView: [ | v |
			self visualize ]
]

{ #category : #initialization }
HTVModel >> initialize [
	super initialize.
	functionCalls := OrderedCollection new.
	functionDefinitions := OrderedCollection new
]

{ #category : #'public - metrics' }
HTVModel >> numberOfCalls [
	^ functionCalls size
]

{ #category : #'public - metrics' }
HTVModel >> numberOfFunctionDefinitions [
	^ functionDefinitions size
]

{ #category : #'public - parsing memory' }
HTVModel >> parseMemoryJSONAsStream: stream [
	| v |
	v := (NeoJSONReader on: stream) next.
	(v includesKey: 'monitor') ifFalse: [ self error: 'Incorrect format for memory' ].
	self halt.

	
	((v at: 'monitor') at: 'function') do: [ :arr |
		self halt.
	]

]

{ #category : #'public - parsing memory' }
HTVModel >> parseMemoryJSONAsText: aJSONAsText [

	^ self parseMemoryJSONAsStream: aJSONAsText readStream
]

{ #category : #'public - parsing trace' }
HTVModel >> parseTraceJSONAsStream: stream [
	| v |
	v := (NeoJSONReader on: stream) next.
	((v at: 'format') = 'memviz' and: [ (v at: 'version') = '0.0.1' ]) 
		ifFalse: [ self error: 'Incorrect format version number' ].
	
	self processSymbolTable: (v at: 'symbols').
	self processCalls: (v at: 'calls').

	self bindCallsToFunctions
]

{ #category : #'public - parsing trace' }
HTVModel >> parseTraceJSONAsText: aJSONAsText [

	^ self parseTraceJSONAsStream: aJSONAsText readStream
]

{ #category : #'private - parsing trace' }
HTVModel >> processCalls: vs [

	| ds |
	vs do: [ :v |
		ds := v at: 'calls'.
		
		ds do: [ :d |
			"If the compiler knows which function is called or not"
			(d at: 'cnt') isArray
				ifTrue: [ self processUnknownCall: d ]
				ifFalse: [ self processKnownCall: d ]
		]
	]
]

{ #category : #'private - parsing trace' }
HTVModel >> processKnownCall: d [
	
	| c |
	c := HTVFunctionCall new.
	c targetChar: (d at: 'target').
	c positionStart: (d at: 'point').
	c numberOfExecutions: (d at: 'cnt').
	functionCalls add: c
]

{ #category : #'private - parsing trace' }
HTVModel >> processSymbolTable: d [

	| fDef |
	d do: [ :dd |
		fDef := HTVFunctionDefinition new.
		fDef functionName: (dd at: 'name').
		fDef positionStart: (dd at: 'point').
		fDef positionEnd: (dd at: 'endpoint').
		fDef type: (dd at: 'type').
		functionDefinitions add: fDef
	] 
]

{ #category : #'private - parsing trace' }
HTVModel >> processUnknownCall: d [
	| c |
	(d at: 'cnt') do: [ :dd |
		c := HTVFunctionCall new.
		c positionStart: (d at: 'point').
		c targetChar: (dd at: 'target').
		c numberOfExecutions: (dd at: 'cnt').
		self assert: [ c numberOfExecutions isInteger ].
		functionCalls add: c ].
]

{ #category : #visualization }
HTVModel >> visualize [
	| b |
	b := RTMondrian new.
	b nodes: functionDefinitions.
	b edges connectToAll: #outgoingFunctions.
	b layout tree.
	b normalizer
		normalizeSize: #numberOfExecutions;
		normalizeColor: #numberOfExecutions.
	^ b
]
