Class {
	#name : #HTVFunctionCall,
	#superclass : #Object,
	#instVars : [
		'functionDefinition',
		'numberOfExecutions',
		'outgoingCalls',
		'positionStart',
		'positionEnd',
		'targetChar'
	],
	#category : #HopTraceVisualization
}

{ #category : #accessing }
HTVFunctionCall >> functionDefinition [
	^ functionDefinition
]

{ #category : #accessing }
HTVFunctionCall >> functionDefinition: anObject [
	functionDefinition := anObject
]

{ #category : #initialization }
HTVFunctionCall >> initialize [

	super initialize.
	positionStart := -1.
"	functionName := 'anonymous'."
	outgoingCalls := OrderedCollection new.
	numberOfExecutions := 0.
]

{ #category : #accessing }
HTVFunctionCall >> numberOfExecutions [
	^ numberOfExecutions
]

{ #category : #accessing }
HTVFunctionCall >> numberOfExecutions: anInteger [
	self assert: [ anInteger isInteger ].
	numberOfExecutions := anInteger
]

{ #category : #accessing }
HTVFunctionCall >> outgoingCalls [
	^ outgoingCalls
]

{ #category : #accessing }
HTVFunctionCall >> outgoingCalls: anObject [
	outgoingCalls := anObject
]

{ #category : #accessing }
HTVFunctionCall >> position [
	^ positionStart
]

{ #category : #accessing }
HTVFunctionCall >> position: anObject [
	positionStart := anObject
]

{ #category : #printing }
HTVFunctionCall >> printOn: str [
	super printOn: str.
	str nextPut: $<.
	"functionName ifNotNil: [ str nextPutAll: functionName ]."
	str nextPut: $>
]

{ #category : #accessing }
HTVFunctionCall >> targetChar [
	^ targetChar
]

{ #category : #accessing }
HTVFunctionCall >> targetChar: anObject [
	targetChar := anObject
]
