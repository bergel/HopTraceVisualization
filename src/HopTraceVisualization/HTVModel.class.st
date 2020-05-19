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
		(fromFunction notNil and: [ toFunction notNil ]) ifTrue: [
			fromFunction addOutgoingFunction: toFunction.
			toFunction addIncomingFunction: fromFunction.
			fromFunction addOutgoingCall: c.
			toFunction addIncomingCall: c ] 
		]
	
]

{ #category : #'private - parsing trace' }
HTVModel >> functionDefAtChar: aCharIndex [
	"Use the symbol table to look up the function at a given char"
	
	| candidateFunctions |
	candidateFunctions := functionDefinitions select: [ :f | f includesCharIndex: aCharIndex ].
	candidateFunctions isEmpty ifTrue: [ ^ nil ]. 
	^ candidateFunctions detectMin: #lengthInCharacters.
"	| selectedFunctionDef offsetFromBegining |
	selectedFunctionDef := functionDefinitions first.
	offsetFromBegining := aCharIndex - selectedFunctionDef positionStart.
	functionDefinitions do: [ :f |
		((f positionStart <= aCharIndex) and: [ (offsetFromBegining > (aCharIndex - f positionStart)) and: [ aCharIndex <= f positionEnd ] ]) 
			ifTrue: [ selectedFunctionDef := f.
						 offsetFromBegining := aCharIndex - f positionStart ]
		 ].
	Halt if: [ selectedFunctionDef functionName = 'Cons.prototype.toString' ].
	^ selectedFunctionDef"
]

{ #category : #visualization }
HTVModel >> gtInspectorViewIn: composite [
	<gtInspectorPresentationOrder: -10>
	composite roassal3
		title: 'View';
		initializeCanvas: [ self visualize ]
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

"	((functionDefinitions collect: #positionStart) select: [ :i | #(11134 9241 9241 11008 6198 5856 12976 6984 6984 12928 5703 11908 14181 13978 14181 11519 14048 804 4005 485 1047 120 2724 8284 3851 17192 17192 ) includes: i ]) size"

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

	| c functionShapes eb interaction searchInteraction |
	c := RSCanvas new.
	functionShapes := functionDefinitions collect: [ :f |
			(RSBox new model: f) @ RSDraggable @ RSPopup.
		 ] as: RSGroup.
	c addAll: functionShapes.
	eb := RSEdgeBuilder arrowedLine
		canvas: c.
	eb moveBehind.
	eb color: Color gray.
	eb
		withBorderAttachPoint;
		connectToAll: #outgoingFunctions.
	RSNormalizer size
		shapes: functionShapes;
		normalize: #numberOfExecutions.
	RSNormalizer color
		shapes: functionShapes;
		from: Color gray;
		to: Color red;
		normalize: #numberOfExecutions.
	
	interaction := RSHighlightable new.
	interaction highlightBorder: (RSBorder new width: 2).
	interaction withEdges.
	functionShapes @ interaction.
	
	RSTreeLayout on: functionShapes.
	searchInteraction := RSSearchInCanvas new.
	searchInteraction 
		doNotUseExactMatch; 
		colorToHighlight: Color blue.
	^ c @ (RSCanvasController new addInteraction: searchInteraction; yourself)

"
USING ROASSAL2
	| b |
	b := RTMondrian new.
	b nodes: functionDefinitions.
	b edges connectToAll: #outgoingFunctions.
	b layout tree.
	b normalizer
		normalizeSize: #numberOfExecutions;
		normalizeColor: #numberOfExecutions.
	^ b"
]
