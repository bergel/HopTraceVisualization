Class {
	#name : #HTVFunctionDefinition,
	#superclass : #Object,
	#instVars : [
		'functionName',
		'outgoingCalls',
		'incomingCalls',
		'outgoingFunctions',
		'incomingFunctions',
		'positionStart',
		'positionEnd',
		'type'
	],
	#category : #HopTraceVisualization
}

{ #category : #adding }
HTVFunctionDefinition >> addIncomingCall: c [
	incomingCalls add: c
]

{ #category : #adding }
HTVFunctionDefinition >> addIncomingFunction: f [
	incomingFunctions add: f
]

{ #category : #adding }
HTVFunctionDefinition >> addOutgoingCall: c [
	outgoingCalls add: c
]

{ #category : #adding }
HTVFunctionDefinition >> addOutgoingFunction: f [
	outgoingFunctions add: f.
	
]

{ #category : #accessing }
HTVFunctionDefinition >> functionName [
	^ functionName
]

{ #category : #accessing }
HTVFunctionDefinition >> functionName: anObject [
	functionName := anObject
]

{ #category : #testing }
HTVFunctionDefinition >> includesCharIndex: aCharIndex [
	"Return true if the provided char index is comprised in the function definition"
	^ (positionStart to: positionEnd + 1) includes: aCharIndex
]

{ #category : #initialization }
HTVFunctionDefinition >> initialize [
	super initialize.
	outgoingCalls := OrderedCollection new.
	incomingCalls := OrderedCollection new.
	outgoingFunctions := OrderedCollection new.
	incomingFunctions := OrderedCollection new.
]

{ #category : #testing }
HTVFunctionDefinition >> lengthInCharacters [
	^ positionEnd - positionStart
]

{ #category : #accessing }
HTVFunctionDefinition >> numberOfExecutions [
	incomingCalls ifEmpty: [ ^ 1 ].
	^ (incomingCalls collect: #numberOfExecutions) sum
]

{ #category : #accessing }
HTVFunctionDefinition >> outgoingCalls [
	^ outgoingCalls
]

{ #category : #accessing }
HTVFunctionDefinition >> outgoingCalls: anObject [
	outgoingCalls := anObject
]

{ #category : #initialization }
HTVFunctionDefinition >> outgoingFunctions [
	^ outgoingFunctions
]

{ #category : #accessing }
HTVFunctionDefinition >> positionEnd [
	^ positionEnd
]

{ #category : #accessing }
HTVFunctionDefinition >> positionEnd: anObject [
	positionEnd := anObject
]

{ #category : #accessing }
HTVFunctionDefinition >> positionStart [
	^ positionStart
]

{ #category : #accessing }
HTVFunctionDefinition >> positionStart: anObject [
	positionStart := anObject
]

{ #category : #printing }
HTVFunctionDefinition >> printOn: str [
	super printOn: str.
	str nextPut: $<.
	functionName ifNotNil: [ str nextPutAll: functionName ].
	str nextPut: $>
]

{ #category : #accessing }
HTVFunctionDefinition >> type [
	^ type
]

{ #category : #accessing }
HTVFunctionDefinition >> type: anObject [
	type := anObject
]
