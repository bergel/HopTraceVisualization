Class {
	#name : #HTVModel,
	#superclass : #Object,
	#instVars : [
		'functionCalls'
	],
	#category : #HopTraceVisualization
}

{ #category : #initialization }
HTVModel >> initialize [
	super initialize.
	functionCalls := OrderedCollection new
]

{ #category : #parsing }
HTVModel >> parseJSONAsStream: stream [
	| v ds |
	v := (NeoJSONReader on: stream) next.
	ds := (v at: 'calls') first at: 'calls'.
	
	
	ds do: [ :d |
		"If the compiler knows which function is called or not"
		(d includesKey: 'name') 
			ifTrue: [ self processKnownCall: d ]
			ifFalse: [ self processUnknownCall: d ]
	]
]

{ #category : #parsing }
HTVModel >> parseJSONAsText: aJSONAsText [

	^ self parseJSONAsStream: aJSONAsText readStream
]

{ #category : #'as yet unclassified' }
HTVModel >> processKnownCall: d [
	
	| c |
	c := HTVFunctionCall new.
	c functionName: (d at: 'name').
	c position: (d at: 'point').
	c numberOfExecutions: (d at: 'cnt').
	functionCalls add: c
]

{ #category : #'as yet unclassified' }
HTVModel >> processUnknownCall: d [
	| c |
	(d at: 'cnt') do: [ :dd |
		c := HTVFunctionCall new.
		c position: (dd at: 'point').
		c functionName: (dd at: 'name').
		c numberOfExecutions: (dd at: 'cnt').
		self assert: [ c numberOfExecutions isInteger ].
		functionCalls add: c ].
]
