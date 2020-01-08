Class {
	#name : #HTVModel,
	#superclass : #Object,
	#instVars : [
		'functionCalls',
		'functionDefinitions'
	],
	#category : #HopTraceVisualization
}

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

{ #category : #parsing }
HTVModel >> parseJSONAsStream: stream [
	| v |
	v := (NeoJSONReader on: stream) next.
	((v at: 'format') = 'memviz' and: [ (v at: 'version') = '0.0.1' ]) 
		ifFalse: [ self error: 'Incorrect format version number' ].
	
	self processSymbolTable: (v at: 'symbols').
	self processCalls: (v at: 'calls').

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
	c position: (d at: 'point').
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
		c position: (d at: 'point').
		c targetChar: (dd at: 'target').
		c numberOfExecutions: (dd at: 'cnt').
		self assert: [ c numberOfExecutions isInteger ].
		functionCalls add: c ].
]
