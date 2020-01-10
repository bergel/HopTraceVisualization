Class {
	#name : #HTVModel,
	#superclass : #Object,
	#instVars : [
		'functionCalls',
		'functionDefinitions'
	],
	#category : #HopTraceVisualization
}

{ #category : #'as yet unclassified' }
HTVModel >> bindCallsToFunctions [
	| fromFunction toFunction |
	functionCalls do: [ :c |
		fromFunction := self functionDefAtChar: c positionStart.
		toFunction := self functionDefAtChar: c targetChar.
		fromFunction addOutgoingFunction: toFunction.
		toFunction addIncomingFunction: fromFunction.
		fromFunction addOutgoingCall: c.
		toFunction addIncomingCall: c.
		 ]
	
]

{ #category : #'as yet unclassified' }
HTVModel >> functionDefAtChar: aCharIndex [
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

{ #category : #'as yet unclassified' }
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

{ #category : #'as yet unclassified' }
HTVModel >> numberOfCalls [
	^ functionCalls size
]

{ #category : #'as yet unclassified' }
HTVModel >> numberOfFunctionDefinitions [
	^ functionDefinitions size
]

{ #category : #parsing }
HTVModel >> parseJSONAsStream: stream [
	| v |
	v := (NeoJSONReader on: stream) next.
	((v at: 'format') = 'memviz' and: [ (v at: 'version') = '0.0.1' ]) 
		ifFalse: [ self error: 'Incorrect format version number' ].
	
	self processSymbolTable: (v at: 'symbols').
	self processCalls: (v at: 'calls').

	self bindCallsToFunctions
]

{ #category : #parsing }
HTVModel >> parseJSONAsText: aJSONAsText [

	^ self parseJSONAsStream: aJSONAsText readStream
]

{ #category : #parsing }
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

{ #category : #'as yet unclassified' }
HTVModel >> processKnownCall: d [
	
	| c |
	c := HTVFunctionCall new.
	c targetChar: (d at: 'target').
	c positionStart: (d at: 'point').
	c numberOfExecutions: (d at: 'cnt').
	functionCalls add: c
]

{ #category : #'as yet unclassified' }
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

{ #category : #'as yet unclassified' }
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

{ #category : #'as yet unclassified' }
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
