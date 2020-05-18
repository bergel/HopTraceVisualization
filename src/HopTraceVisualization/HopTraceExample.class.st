Class {
	#name : #HopTraceExample,
	#superclass : #Object,
	#category : #HopTraceVisualization
}

{ #category : #'as yet unclassified' }
HopTraceExample >> javaScriptExample [

	^ '-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----
"use strict";

// Adapted by Manuel Serrano from Olin Shivers''s maze.scm program
// Copyright (c) 1993 by Olin Shivers.
function Cons( car, cdr ) {
  this.car = car;
  this.cdr = cdr;
}

Cons.prototype.toString = function() {
  return "(" + this.car + (this.cdr instanceof Cons ? " " + this.cdr.toString() : "") + ")";
}

Cons.prototype.toConsString = function() {
  return "(" + this.car + " . " + this.cdr + ")";
}

function CONS( car, cdr ) {
  return new Cons( car, cdr );
}

function Harr( nrows, ncols, elts ) {
  this.nrows = nrows;
  this.ncols = ncols;
  this.elts = elts;
}

Harr.prototype.hrefRC = function( r, c ) {
  return this.elts[ this.ncols * r + c ];
}

Harr.prototype.href = function( x, y ) {
  let r = y / 2 >> 0;
  let c = x / 3 >> 0;

  return this.hrefRC( r, c );
}

function Wall( owner, neighbor, bit ) {
  this.owner = owner;       // Box that owns this wall.
  this.neighbor = neighbor; // The other box bordering this wall.
  this.bit = bit;           // a bit identifying this wall in OWNER''s box.
}

function Box( reachable, id, walls = -1, parent = false, mark = false ) {
  this.reachable = reachable; // Union/find set -- all reachable boxs.
  this.id = id;               // Identifying info (e.g., the coords of the box)
  this.walls = walls       // A bitset telling which walls are still standing. 
  this.parent = parent;    // For DFS spanning tree construction.
  this.mark = mark;        // For marking the solution path.
}

// Hex arrays
// Copyright (c) 1995 by Olin Shivers.

// External dependencies:
// - define-record

//        ___       ___       ___
//       /   \     /   \     /   \
//   ___/  A  \___/  A  \___/  A  \___
//  /   \     /   \     /   \     /   \
// /  A  \___/  A  \___/  A  \___/  A  \
// \     /   \     /   \     /   \     /
//  \___/     \___/     \___/     \___/
//  /   \     /   \     /   \     /   \
// /     \___/     \___/     \___/     \
// \     /   \     /   \     /   \     /
//  \___/     \___/     \___/     \___/
//  /   \     /   \     /   \     /   \
// /     \___/     \___/     \___/     \
// \     /   \     /   \     /   \     /
//  \___/     \___/     \___/     \___/

// Hex arrays are indexed by the (x,y) coord of the center of the hexagonal
// element. Hexes are three wide and two high; e.g., to get from the center
// of an elt to its {NW, N, NE} neighbors, add {(-3,1), (0,2), (3,1)}
// respectively.
//
// Hex arrays are represented with a matrix, essentially made by shoving the
// odd columns down a half-box so things line up. The mapping is as follows:
//     Center coord      row/column
//     ------------      ----------
//     (x,  y)        -> (y/2, x/3)
//     (3c, 2r + c&1) <- (r,   c)

function harrTabulate( nrows, ncols, proc ) {
  const v = new Array( nrows * ncols );

  for( let r = nrows - 1; !(r < 0); r-- ) {
     for( let c = 0, i = r * ncols; !(c === ncols); c++, i++ ) {
	 v[ i ] = proc( c * 3, 2 * r + (c & 1) );
     }
  }

  return new Harr( nrows, ncols, v );
}


// Hexagonal hackery for maze generation.
// Copyright (c) 1995 by Olin Shivers.

// Every elt of the hex array manages his SW, S, and SE wall.
// Terminology: - An even column is one whose column index is even. That
//                means the first, third, ... columns (indices 0, 2, ...).
//              - An odd column is one whose column index is odd. That
//                means the second, fourth... columns (indices 1, 3, ...).
//              The even/odd flip-flop is confusing; be careful to keep it
//              straight. The *even* columns are the low ones. The *odd*
//              columns are the high ones.
//    _   _
//  _/ \_/ \
// / \_/ \_/
// \_/ \_/ \
// / \_/ \_/
// \_/ \_/ \
// / \_/ \_/
// \_/ \_/ \
// / \_/ \_/
// \_/ \_/
//  0 1 2 3
const SOUTHWEST = 1;
const SOUTH = 2;
const SOUTHEAST = 4;

function genMazeArray( r, c ) {
  return harrTabulate( r, c, (x, y) => new Box( baseSet( 1 ), CONS( x, y ) ) );
}

// This could be made more efficient.
function makeWallVec( harr ) {
  let nrows = harr.nrows;
  let ncols = harr.ncols;
  let xmax = 3 * (ncols - 1);
  let walls = []; // Accumulate walls.

  function addWall( o, n, b ) { // owner neighbor bit
     walls.push( new Wall( o, n, b ) );
  }

  // Do everything but the bottom row.
  for( let x = 3 * (ncols - 1); !(x < 0); x -= 3 ) {
     for( let y = ((nrows - 1) * 2 ) + (x & 1); !(y <= 1); y -= 2 ) {
	 // don''t do bottom row.
	 let hex = harr.href( x, y );

	 if( x !== 0 ) addWall( hex, harr.href( x - 3, y - 1 ), SOUTHWEST );
	 addWall( hex, harr.href( x, y - 2 ), SOUTH );
	 if( x < xmax ) addWall( hex, harr.href( x + 3, y - 1 ), SOUTHEAST );
     }
  }

  // Do the SE and SW walls of the odd columns on the bottom row.
  // If the rightmost bottom hex lies in an odd column, however,
  // don''t add it''s SE wall -- it''s a corner hex, and has no SE neighbor.
  if( ncols > 1 ) {
     let rmocX = ~~(3 + (6 * ((ncols - 2) >> 1)));
     let rmocHex = harr.href( rmocX, 1 );

     if( rmocX < xmax ) { // Not a corner == do E wall.
	 addWall( rmocHex, harr.href( xmax, 0 ), SOUTHEAST );
     }
     addWall( rmocHex, harr.href( rmocX - 3, 0 ), SOUTHWEST );

     for( let x = rmocX - 6; !(x < 3); x -= 6 ) {
	 addWall( harr.href( x, 1 ), harr.href( x - 3, 0 ), SOUTHWEST );
	 addWall( harr.href( x, 1 ), harr.href( x + 3, 0 ), SOUTHEAST );
     }
  }

  return walls.reverse();
}

let TPLPres = {entrance: false, exit: false };
let BTLPres = { maxlen: false, trance: false, xit: false };

// Find the box ctop from the top row, and the box cbot from the bottom
// row such that cbot is furthest from ctop. 
// Return [ctop-x, ctop-y, cbot-x, cbot-y].
function pickEntrances( harr ) {
  let nrows = harr.nrows;
  let ncols = harr.ncols;

  dfsMaze( harr, harr.hrefRC( 0, 0 ), forEachHexChild );

  function TPLP( maxLen, entrance, exit, tcol ) {
/*       console.log( "TPLP maxlen=", maxLen, " entrance=", entrance, " exit=", exit, " tcol=", tcol ); */
     if( tcol < 0 ) {
	 TPLPres.entrance = entrance;
	 TPLPres.exit = exit;
	 
	 return TPLPres;
     } else {
	 let topBox = harr.hrefRC( nrows - 1, tcol );
	 rerootMaze( topBox );

	 function BTLP( maxLen, entrance, exit, bcol ) {
/* 	    console.log( "  BTLP maxlen=", maxLen, " entrance=", entrance, " exit=", exit, " bcol=", bcol ); */
	    if( bcol < 0 ) {
	       BTLPres.maxlen = maxLen;
	       BTLPres.trance = entrance;
	       BTLPres.xit = exit;
	       return BTLPres;
	    } else {
	       const thisLen = pathLength( harr.hrefRC( 0, bcol ) );

	       if( thisLen > maxLen ) {
		  return BTLP( thisLen, tcol, bcol, bcol - 1);
	       } else {
		  return BTLP( maxLen, entrance, exit, bcol - 1);
	       }
	    }
	 }

	 let { maxlen, trance, xit } =
	     BTLP( maxLen, entrance, exit, ncols - 1);

	 return TPLP( maxlen, trance, xit, tcol - 1);
     }
  }

  return TPLP( -1, false, false, ncols - 1);
}

// Apply PROC to each node reachable from BOX.
function forEachHexChild( proc, harr, box ) {
  const walls = box.walls;
  const id = box.id;
  const x = id.car;
  const y = id.cdr;
  const nr = harr.nrows;
  const nc = harr.ncols;
  const maxy = 2 * (nr - 1);
  const maxx = 3 * (nc - 1);

  if( !bitTest( walls, SOUTHWEST ) ) proc( harr.href( x - 3, y - 1 ) );
  if( !bitTest( walls, SOUTH ) ) proc( harr.href( x, y - 2 ) );
  if( !bitTest( walls, SOUTHEAST ) ) proc( harr.href( x + 3, y - 1 ) );

  // NW neighbor, if there is one (we may be in col 1, or top row/odd col)
  if( x > 0 // Not in first column.
      && (y <= maxy // Not on top row or
	   || (x % 6) === 0) ) { // Not in an odd column.
     let nw = harr.href( x - 3, y + 1 );
     if( !bitTest( nw.walls, SOUTHEAST ) ) proc( nw );
  }

  // N neighbor, if there is one (we may be on top row).
  if( y < maxy ) { // Not on top row
     let n = harr.href( x, y + 2 );
     if( !bitTest( n.walls, SOUTH ) ) proc( n );
  }

  // NE neighbor, if there is one (we may be in last col, or top row/odd col)
  if( x < maxx // ; Not in last column.
      && (y <= maxy // Not on top row or
	   || (x % 6) === 0) ) { // ; not in an odd column.
     let ne = harr.href( x + 3, y + 1 );
     if( !bitTest( ne.walls, SOUTHWEST ) ) proc( ne );
  }
}

// The top-level
function makeMaze( nrows, ncols ) {
  let boxs = genMazeArray( nrows, ncols );
  let walls = permuteVec( makeWallVec( boxs ), randomState( 20 ) );

  digMaze( walls, nrows * ncols );

  let { entrance, exit } = pickEntrances( boxs );

  let exitBox = boxs.hrefRC( 0, exit );
  let nwalls = exitBox.walls;

  rerootMaze( boxs.hrefRC( nrows - 1, entrance ) );
  markPath( exitBox );
  exitBox.walls = nwalls & ~SOUTH;

  return { boxs, entrance, exit };
}

function pmaze( nrows, ncols ) {
  let { boxs, entrance, exit } = makeMaze( nrows, ncols );

  printHexMaze( boxs, entrance );
}

// Print out a hex array with characters.
// Copyright (c) 1995 by Olin Shivers.

// External dependencies:
// - hex array code
// - hex box code

//    _   _
//  _/ \_/ \
// / \_/ \_/
// \_/ \_/ \
// / \_/ \_/
// \_/ \_/ \
// / \_/ \_/
// \_/ \_/ \
// / \_/ \_/
// \_/ \_/ 

// Top part of top row looks like this:
//    _   _  _   _
//  _/ \_/ \/ \_/ \
// /
function printHexMaze( harr, entrance ) {
  let nrows = harr.nrows;
  let ncols = harr.ncols;
  let ncols2 = (ncols >> 1) << 1;

  // Print out the flat tops for the top row''s odd cols.
  for( let c = 1; !(c >= ncols); c+= 2 ) {
     display( "   " );
     writeChar( c === entrance ? " " : "_" );
  }
  newline();

  // Print out the slanted tops for the top row''s odd cols
  // and the flat tops for the top row''s even cols.
  writeChar( " " );
  for( let c = 0; !(c >= ncols2); c += 2 ) {
     display( c === entrance ? " " : "_" );
     display( "/" );
     display( dotSpace( harr, nrows - 1, c + 1 ) );
     display( "\\" );
  }

  if( ncols & 1 ) writeChar( entrance === (ncols - 1) ? " " : "_" );
  newline();

  for( let r = nrows - 1; !(r < 0); r-- ) {
     // Do the bottoms for row r''s odd cols.
     writeChar( "/" );
     for( let c = 1; !(c >= ncols2); c += 2 ) {
	 // The dot/space for the even col just behind c.
	 writeChar( dotSpace( harr, r, c - 1 ) );
	 displayHexBottom( harr.hrefRC( r, c ).walls );
     }

     if( ncols & 1 ) {
	 writeChar( dotSpace( harr, r, ncols - 1 ) );
	 writeChar( "\\" );
     }

     newline();

     // Do the bottoms for row r''s even cols.
     for( let c = 0; !(c >= ncols2); c += 2 ) {
	 displayHexBottom( harr.hrefRC( r, c ).walls );
	 // The dot/space is for the odd col just after c, on row below.
	 writeChar( dotSpace( harr, r - 1, c + 1 ) );
     }

     if( ncols & 1 ) {
	 displayHexBottom( harr.hrefRC( r, ncols - 1 ).walls );
     } else if( r !== 0 ) {
	 writeChar( "\\" );
     }

     newline();
  }
}

function bitTest( j, bit ) {
  return (j & bit) !== 0;
}

// Return a . if harr[r,c] is marked, otherwise a space.
// We use the dot to mark the solution path.
function dotSpace( harr, r, c ) {
  return ( r >= 0 && harr.hrefRC( r, c ).mark ) ? "." : " ";
}

// Print a \_/ hex bottom.
function displayHexBottom( hexwalls ) {
  writeChar( bitTest( hexwalls, SOUTHWEST ) ? "\\" : " " );
  writeChar( bitTest( hexwalls, SOUTH ) ? "_" : " " );
  writeChar( bitTest( hexwalls, SOUTHEAST ) ? "/" : " " );
}

//    _   _
//  _/ \_/ \
// / \_/ \_/
// \_/ \_/ \_/
// / \_/ \_/
// \_/ \_/ \
// / \_/ \_/
// \_/ \_/ \
// / \_/ \_/
// \_/ \_/ \_/


// Randomly permute a vector.
function permuteVec( v, randomState ) {
  for( let i = v.length - 1; i > 1; i-- ) {
     let eli = v[ i ];
     let j = randomInt( i, randomState );

     v[ i ] = v[ j ];
     v[ j ] = eli;
  }

  return v;
}

Array.prototype.forEachRev = function( proc ) {
  for( let i = this.length - 1; i >= 0; i-- ) {
     proc( this[ i ] );
  }
}

// This is the core of the algorithm.
function digMaze( walls, nboxs ) {
  try {
     walls.forEachRev( wall => { // For each wall,
	 let c1 = wall.owner;     // find the boxs on
	 let set1 = c1.reachable;
	 let c2 = wall.neighbor; // each side of the wall
	 let set2 = c2.reachable;

	 // If there is no path from c1 to c2, knock down the
	 // wall and union the two sets of reachable boxs.
	 // If the new set of reachable boxs is the whole set
	 // of boxs, quit.
	 if( !setEqual( set1, set2 ) ) {
	    let nwalls = c1.walls;
	    let wallmask = ~wall.bit;
	    union( set1, set2 );

	    c1.walls = nwalls & wallmask;
	    if( setSize( set1 ) === nboxs ) {
	       throw false;
	    }
	 }
     } );
  } catch( exn ) {
     if( exn ) throw exn;
     ;
  }
}

// Some simple DFS routines useful for determining path length 
// through the maze.

// Build a DFS tree from ROOT. 
// (DO-CHILDREN proc maze node) applies PROC to each of NODE''s children.
// We assume there are no loops in the maze; if this is incorrect, the
// algorithm will diverge.
function dfsMaze( maze, root, doChildren ) {
  function search( node, parent ) {
     node.parent = parent;
     return doChildren( child => {
	 if( child !== parent ) search( child, node );
     }, maze, node );
  }

  return search( root, false );
}

// Move the root to NEW-ROOT
function rerootMaze( newRoot ) {
  function lp( node, newParent ) {
     let oldParent = node.parent;
     node.parent = newParent;
     if( oldParent ) lp( oldParent, node );
  }

  return lp( newRoot, false );
}

//  How far from BOX to the root?
function pathLength( box ) {
  let len = 0;
  let node = box.parent;

  for( ; !!node; len++, node = node.parent );

  return len;
}

// Mark the nodes from NODE back to root. Used to mark the winning path.
function markPath( node ) {
  node.mark = true;
  if( node.parent ) markPath( node.parent );
}

// Minimal Standard Random Number Generator
// Park & Miller, CACM 31(10), Oct 1988, 32 bit integer version.
// better constants, as proposed by Park.
// By Ozan Yigit

// Rehacked by Olin 4/1995.

function fx28( a ) {
  return ((1 << 28) - 1) & a;
}

// randomState
function *randomState( n ) {
  const A = 48271;
  const M = 268435455;
  const Q = 44488;
  const R = 3399;
  let seed = n;

  while( true ) {
     let hi = fx28( seed / Q );
     let lo = fx28( seed % Q );
     let test = fx28( fx28( A * lo ) - fx28( R * hi ) );
     let val = test > 0 ? test : fx28( test + M );

     yield val;
     seed = val;
  }
}

function rand( state ) {
  return state.next().value;
}

// rand

// randomInt
function randomInt( n, state ) {
  return fx28( rand( state ) % n );
}

// Tarjan''s amortised union-find data structure.
// Copyright (c) 1995 by Olin Shivers.

// This data structure implements disjoint sets of elements.
// Four operations are supported. The implementation is extremely
// fast -- any sequence of N operations can be performed in time
// so close to linear it''s laughable how close it is. See your
// intro data structures book for more. The operations are:
//
// - (base-set nelts) -> set
//   Returns a new set, of size NELTS.
//
// - (set-size s) -> integer
//   Returns the number of elements in set S.
//
// - (union! set1 set2)
//   Unions the two sets -- SET1 and SET2 are now considered the same set
//   by SET-EQUAL?.
//
// - (set-equal? set1 set2)
//   Returns true <==> the two sets are the same.

// Representation: a set is a cons box. Every set has a "representative"
// cons box, reached by chasing cdr links until we find the cons with
// cdr = (). Set equality is determined by comparing representatives using
// EQ?. A representative''s car contains the number of elements in the set.

// The speed of the algorithm comes because when we chase links to find 
// representatives, we collapse links by changing all the boxs in the path
// we followed to point directly to the representative, so that next time
// we walk the cdr-chain, we''ll go directly to the representative in one hop.
function baseSet( nelts ) {
  return CONS( nelts, null );
}

// Sets are chained together through cdr links. Last guy in the chain
// is the root of the set.
function getSetRoot( s ) {
  function lp( r ) { // Find the last pair
     let next = r.cdr; // in the list. That''s
     if( next ) { // the root r.
	 return lp( next );
     } else {
	 if( r !== s ) { // Now zip down the list again,
	    function lq( x ) {  // changing everyone''s cdr to r.
	       let next = x.cdr;
	       if( r !== next ) {
		  x.cdr = r;
		  return lq( next );
	       }
	    }

	    lq( s );
	 }

	 return r;
     }
  }

  return lp( s );
}

function setEqual( s1, s2 ) {
  return getSetRoot( s1 ) === getSetRoot( s2 );
}

function setSize( s ) {
  return getSetRoot( s ).car;
}

function union( s1, s2 ) {
  let r1 = getSetRoot( s1 );
  let r2 = getSetRoot( s2 );
  let n1 = setSize( r1 );
  let n2 = setSize( r2 );
  let n = n1 + n2;

  if( n1 > n2 ) {
     r2.cdr = r1;
     r1.car = n;
  } else {
     r1.cdr = r2;
     r2.car = n;
  }
}

var stdio = true;

function display( str ) {
  if( stdio != null ) {
     process.stdout.write( str );
  }
}

function writeChar( char ) {
  return display( char );
}

function newline() {
  return display( "\n" );
}

function main( bench, n ) {
  let res = 0;
  const k = Math.round( n / 10 );
  let i = 1;

  console.log( bench + "(", n, ")..." );

  stdio = null;
  while( n-- > 0 ) {
     if( n % k === 0 ) { console.log( i++ ); }
     pmaze( 100, 100 );
  }
  stdio = true;

  pmaze( 10, 35 );
}

const N = 
  (process.argv[ 1 ] === "fprofile") 
  ? 2
  : process.argv[ 2 ] ? parseInt( process.argv[ 2 ] ) : 200;

main( "maze", N ); '
]

{ #category : #'as yet unclassified' }
HopTraceExample >> memoryExample [

^ '{"monitor":
 { "info": { "exec": "./a.out", "version": "0.0.3", "sizeWord": 1 },
  "gc": [
   { "number": 0, "alloc": 4497507, "heap": 4325376, "live": 2408704, "lastfun": "unknown", "time": 1578672633664800000 },
   { "number": 1, "alloc": 4609845, "heap": 7827456, "live": 5423936, "lastfun": "&pthread-103", "time": 1578672633697531000 },
   { "number": 2, "alloc": 6927874, "heap": 13922304, "live": 11670704, "lastfun": { "point": 14181, "file": "maze.js" }, "time": 1578672633746790000 },
   { "number": 3, "alloc": 11569072, "heap": 24760320, "live": 9445824, "lastfun": "for@maze.js:998", "time": 1578672634834055000 },
   { "number": 4, "alloc": 419296, "heap": 24760320, "live": 6717472, "lastfun": "&pthread-103", "time": 1578672634843358000 }]
  ,
 "function": [
  { "function": { "point": 11134, "file": "maze.js" }, "allocs": [
     { "gc": 4, "dsize": 306552, "isize": 0,
       "dtype": [
           { "type": 334, "cnt": 795, "size": 48336 },
           { "type": 3, "cnt": 954, "size": 54696 },
           { "type": 13, "cnt": 1908, "size": 15264 },
           { "type": 30, "cnt": 954, "size": 105576 },
           { "type": 2, "cnt": 954, "size": 26712 },
           { "type": 0, "cnt": 3498, "size": 55968 }] ,
       "itype": [] },
     { "gc": 3, "dsize": 1718920, "isize": 0,
       "dtype": [
           { "type": 334, "cnt": 4455, "size": 270864 },
           { "type": 3, "cnt": 5346, "size": 306504 },
           { "type": 13, "cnt": 10692, "size": 85536 },
           { "type": 30, "cnt": 5346, "size": 591624 },
           { "type": 2, "cnt": 5350, "size": 149800 },
           { "type": 0, "cnt": 19662, "size": 314592 }] ,
       "itype": [] }] },
  { "function": "for@maze.js:943", "allocs": [
     { "gc": 3, "dsize": 68208, "isize": 0,
       "dtype": [
           { "type": 334, "cnt": 170, "size": 10336 },
           { "type": 3, "cnt": 205, "size": 11744 },
           { "type": 13, "cnt": 408, "size": 3264 },
           { "type": 30, "cnt": 205, "size": 22624 },
           { "type": 2, "cnt": 204, "size": 5712 },
           { "type": 0, "cnt": 908, "size": 14528 }] ,
       "itype": [] }] },
  { "function": "for@maze.js:998", "allocs": [
     { "gc": 4, "dsize": 112224, "isize": 306552,
       "dtype": [
           { "type": 30, "cnt": 348, "size": 38512 },
           { "type": 2, "cnt": 348, "size": 9744 },
           { "type": 3, "cnt": 350, "size": 20104 },
           { "type": 0, "cnt": 1280, "size": 20480 },
           { "type": 13, "cnt": 702, "size": 5616 },
           { "type": 334, "cnt": 292, "size": 17768 }] ,
       "itype": [
           { "type": 334, "cnt": 795, "size": 48336 },
           { "type": 3, "cnt": 954, "size": 54696 },
           { "type": 13, "cnt": 1908, "size": 15264 },
           { "type": 30, "cnt": 954, "size": 105576 },
           { "type": 2, "cnt": 954, "size": 26712 },
           { "type": 0, "cnt": 3498, "size": 55968 }] },
     { "gc": 3, "dsize": 642896, "isize": 1718920,
       "dtype": [
           { "type": 334, "cnt": 1658, "size": 100792 },
           { "type": 3, "cnt": 1990, "size": 114056 },
           { "type": 13, "cnt": 3978, "size": 31824 },
           { "type": 30, "cnt": 1992, "size": 220448 },
           { "type": 2, "cnt": 1992, "size": 55776 },
           { "type": 0, "cnt": 7500, "size": 120000 }] ,
       "itype": [
           { "type": 334, "cnt": 4455, "size": 270864 },
           { "type": 3, "cnt": 5346, "size": 306504 },
           { "type": 13, "cnt": 10692, "size": 85536 },
           { "type": 30, "cnt": 5346, "size": 591624 },
           { "type": 2, "cnt": 5350, "size": 149800 },
           { "type": 0, "cnt": 19662, "size": 314592 }] }] },
  { "function": { "point": 9241, "file": "maze.js" }, "allocs": [
     { "gc": 4, "dsize": 0, "isize": 418776,
       "dtype": [] ,
       "itype": [
           { "type": 30, "cnt": 1302, "size": 144088 },
           { "type": 2, "cnt": 1302, "size": 36456 },
           { "type": 3, "cnt": 1304, "size": 74800 },
           { "type": 0, "cnt": 4778, "size": 76448 },
           { "type": 13, "cnt": 2610, "size": 20880 },
           { "type": 334, "cnt": 1087, "size": 66104 }] },
     { "gc": 3, "dsize": 0, "isize": 2571720,
       "dtype": [] ,
       "itype": [
           { "type": 334, "cnt": 6643, "size": 403880 },
           { "type": 3, "cnt": 7973, "size": 457072 },
           { "type": 13, "cnt": 15942, "size": 127536 },
           { "type": 30, "cnt": 7975, "size": 882504 },
           { "type": 2, "cnt": 7978, "size": 223384 },
           { "type": 0, "cnt": 29834, "size": 477344 }] }] },
  { "function": { "point": 9241, "file": "maze.js" }, "allocs": [
     { "gc": 4, "dsize": 0, "isize": 418776,
       "dtype": [] ,
       "itype": [
           { "type": 30, "cnt": 1302, "size": 144088 },
           { "type": 2, "cnt": 1302, "size": 36456 },
           { "type": 3, "cnt": 1304, "size": 74800 },
           { "type": 0, "cnt": 4778, "size": 76448 },
           { "type": 13, "cnt": 2610, "size": 20880 },
           { "type": 334, "cnt": 1087, "size": 66104 }] },
     { "gc": 3, "dsize": 8992, "isize": 2562728,
       "dtype": [
           { "type": 334, "cnt": 20, "size": 1216 },
           { "type": 3, "cnt": 24, "size": 1376 },
           { "type": 13, "cnt": 48, "size": 384 },
           { "type": 30, "cnt": 24, "size": 2656 },
           { "type": 2, "cnt": 24, "size": 672 },
           { "type": 0, "cnt": 168, "size": 2688 }] ,
       "itype": [
           { "type": 334, "cnt": 6623, "size": 402664 },
           { "type": 3, "cnt": 7949, "size": 455696 },
           { "type": 13, "cnt": 15894, "size": 127152 },
           { "type": 30, "cnt": 7951, "size": 879848 },
           { "type": 2, "cnt": 7954, "size": 222712 },
           { "type": 0, "cnt": 29666, "size": 474656 }] }] },
  { "function": "for@maze.js:970", "allocs": [
     { "gc": 3, "dsize": 132384, "isize": 320,
       "dtype": [
           { "type": 334, "cnt": 340, "size": 20672 },
           { "type": 3, "cnt": 408, "size": 23392 },
           { "type": 13, "cnt": 816, "size": 6528 },
           { "type": 30, "cnt": 408, "size": 45152 },
           { "type": 2, "cnt": 408, "size": 11424 },
           { "type": 0, "cnt": 1576, "size": 25216 }] ,
       "itype": [
           { "type": 0, "cnt": 20, "size": 320 }] }] },
  { "function": { "point": 11008, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 320, "isize": 0,
       "dtype": [
           { "type": 0, "cnt": 20, "size": 320 }] ,
       "itype": [] }] },
  { "function": { "point": 6198, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 320, "isize": 0,
       "dtype": [
           { "type": 0, "cnt": 20, "size": 320 }] ,
       "itype": [] }] },
  { "function": { "point": 5856, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 320, "isize": 320,
       "dtype": [
           { "type": 0, "cnt": 20, "size": 320 }] ,
       "itype": [
           { "type": 0, "cnt": 20, "size": 320 }] }] },
  { "function": "maze.js:13063-1708:main@maz", "allocs": [
     { "gc": 3, "dsize": 0, "isize": 3310720,
       "dtype": [] ,
       "itype": [
           { "type": 0, "cnt": 20, "size": 320 },
           { "type": 334, "cnt": 10345, "size": 579320 },
           { "type": 30, "cnt": 10345, "size": 1406920 },
           { "type": 2, "cnt": 10345, "size": 496560 },
           { "type": 3, "cnt": 10345, "size": 827600 }] }] },
  { "function": "maze.js:13063-1709:main@maz", "allocs": [
     { "gc": 3, "dsize": 0, "isize": 3312960,
       "dtype": [] ,
       "itype": [
           { "type": 0, "cnt": 100, "size": 1600 },
           { "type": 334, "cnt": 10348, "size": 579488 },
           { "type": 30, "cnt": 10348, "size": 1407328 },
           { "type": 2, "cnt": 10348, "size": 496704 },
           { "type": 3, "cnt": 10348, "size": 827840 }] }] },
  { "function": { "point": 12976, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 3311360, "isize": 1600,
       "dtype": [
           { "type": 334, "cnt": 10348, "size": 579488 },
           { "type": 30, "cnt": 10348, "size": 1407328 },
           { "type": 2, "cnt": 10348, "size": 496704 },
           { "type": 3, "cnt": 10348, "size": 827840 }] ,
       "itype": [
           { "type": 0, "cnt": 100, "size": 1600 }] }] },
  { "function": { "point": 6984, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 0, "isize": 3313280,
       "dtype": [] ,
       "itype": [
           { "type": 334, "cnt": 10348, "size": 579488 },
           { "type": 30, "cnt": 10348, "size": 1407328 },
           { "type": 2, "cnt": 10348, "size": 496704 },
           { "type": 3, "cnt": 10348, "size": 827840 },
           { "type": 0, "cnt": 120, "size": 1920 }] }] },
  { "function": { "point": 6984, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 1920, "isize": 3311360,
       "dtype": [
           { "type": 0, "cnt": 120, "size": 1920 }] ,
       "itype": [
           { "type": 334, "cnt": 10348, "size": 579488 },
           { "type": 30, "cnt": 10348, "size": 1407328 },
           { "type": 2, "cnt": 10348, "size": 496704 },
           { "type": 3, "cnt": 10348, "size": 827840 }] }] },
  { "function": { "point": 12928, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 624, "isize": 3313280,
       "dtype": [
           { "type": 334, "cnt": 2, "size": 112 },
           { "type": 30, "cnt": 2, "size": 272 },
           { "type": 2, "cnt": 2, "size": 96 },
           { "type": 3, "cnt": 2, "size": 144 }] ,
       "itype": [
           { "type": 334, "cnt": 10348, "size": 579488 },
           { "type": 30, "cnt": 10348, "size": 1407328 },
           { "type": 2, "cnt": 10348, "size": 496704 },
           { "type": 3, "cnt": 10348, "size": 827840 },
           { "type": 0, "cnt": 120, "size": 1920 }] }] },
  { "function": { "point": 5703, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 320, "isize": 3314544,
       "dtype": [
           { "type": 0, "cnt": 20, "size": 320 }] ,
       "itype": [
           { "type": 0, "cnt": 160, "size": 2560 },
           { "type": 334, "cnt": 10350, "size": 579600 },
           { "type": 30, "cnt": 10350, "size": 1407600 },
           { "type": 2, "cnt": 10350, "size": 496800 },
           { "type": 3, "cnt": 10350, "size": 827984 }] }] },
  { "function": { "point": 11908, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 912, "isize": 0,
       "dtype": [
           { "type": 334, "cnt": 2, "size": 112 },
           { "type": 30, "cnt": 2, "size": 272 },
           { "type": 2, "cnt": 2, "size": 96 },
           { "type": 0, "cnt": 4, "size": 64 },
           { "type": 3, "cnt": 6, "size": 336 },
           { "type": 13, "cnt": 4, "size": 32 }] ,
       "itype": [] }] },
  { "function": "<@anonymous:14594>:main@maz", "allocs": [
     { "gc": 3, "dsize": 0, "isize": 5515864,
       "dtype": [] ,
       "itype": [
           { "type": 3, "cnt": 27579, "size": 2868216 },
           { "type": 16, "cnt": 110316, "size": 882528 },
           { "type": 334, "cnt": 27580, "size": 1765120 }] },
     { "gc": 2, "dsize": 0, "isize": 595336,
       "dtype": [] ,
       "itype": [
           { "type": 334, "cnt": 2976, "size": 190464 },
           { "type": 3, "cnt": 2977, "size": 309608 },
           { "type": 16, "cnt": 11908, "size": 95264 }] }] },
  { "function": { "point": 14181, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 0, "isize": 5515864,
       "dtype": [] ,
       "itype": [
           { "type": 3, "cnt": 27579, "size": 2868216 },
           { "type": 16, "cnt": 110316, "size": 882528 },
           { "type": 334, "cnt": 27580, "size": 1765120 }] },
     { "gc": 2, "dsize": 0, "isize": 595336,
       "dtype": [] ,
       "itype": [
           { "type": 334, "cnt": 2976, "size": 190464 },
           { "type": 3, "cnt": 2977, "size": 309608 },
           { "type": 16, "cnt": 11908, "size": 95264 }] }] },
  { "function": { "point": 13978, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 441280, "isize": 0,
       "dtype": [
           { "type": 16, "cnt": 55160, "size": 441280 }] ,
       "itype": [] },
     { "gc": 2, "dsize": 47648, "isize": 0,
       "dtype": [
           { "type": 16, "cnt": 5956, "size": 47648 }] ,
       "itype": [] }] },
  { "function": { "point": 14181, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 5074784, "isize": 441280,
       "dtype": [
           { "type": 3, "cnt": 27580, "size": 2868320 },
           { "type": 16, "cnt": 55160, "size": 441280 },
           { "type": 334, "cnt": 27581, "size": 1765184 }] ,
       "itype": [
           { "type": 16, "cnt": 55160, "size": 441280 }] },
     { "gc": 2, "dsize": 547888, "isize": 47648,
       "dtype": [
           { "type": 334, "cnt": 2977, "size": 190528 },
           { "type": 3, "cnt": 2978, "size": 309712 },
           { "type": 16, "cnt": 5956, "size": 47648 }] ,
       "itype": [
           { "type": 16, "cnt": 5956, "size": 47648 }] }] },
  { "function": "<@anonymous:14589>:main@maz", "allocs": [
     { "gc": 3, "dsize": 16, "isize": 200,
       "dtype": [
           { "type": 13, "cnt": 2, "size": 16 }] ,
       "itype": [
           { "type": 334, "cnt": 1, "size": 64 },
           { "type": 3, "cnt": 1, "size": 104 },
           { "type": 16, "cnt": 4, "size": 32 }] },
     { "gc": 2, "dsize": 16, "isize": 200,
       "dtype": [
           { "type": 13, "cnt": 2, "size": 16 }] ,
       "itype": [
           { "type": 334, "cnt": 1, "size": 64 },
           { "type": 3, "cnt": 1, "size": 104 },
           { "type": 16, "cnt": 4, "size": 32 }] }] },
  { "function": { "point": 11519, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 0, "isize": 5516080,
       "dtype": [] ,
       "itype": [
           { "type": 13, "cnt": 2, "size": 16 },
           { "type": 3, "cnt": 27580, "size": 2868320 },
           { "type": 16, "cnt": 110320, "size": 882560 },
           { "type": 334, "cnt": 27581, "size": 1765184 }] },
     { "gc": 2, "dsize": 0, "isize": 595952,
       "dtype": [] ,
       "itype": [
           { "type": 334, "cnt": 2977, "size": 190528 },
           { "type": 16, "cnt": 11912, "size": 95296 },
           { "type": 13, "cnt": 2, "size": 16 },
           { "type": 0, "cnt": 22, "size": 352 },
           { "type": 3, "cnt": 2979, "size": 309760 }] }] },
  { "function": "for@maze.js:1156", "allocs": [
     { "gc": 3, "dsize": 0, "isize": 5516080,
       "dtype": [] ,
       "itype": [
           { "type": 13, "cnt": 2, "size": 16 },
           { "type": 3, "cnt": 27580, "size": 2868320 },
           { "type": 16, "cnt": 110320, "size": 882560 },
           { "type": 334, "cnt": 27581, "size": 1765184 }] },
     { "gc": 2, "dsize": 400, "isize": 595552,
       "dtype": [
           { "type": 0, "cnt": 22, "size": 352 },
           { "type": 3, "cnt": 1, "size": 48 }] ,
       "itype": [
           { "type": 334, "cnt": 2977, "size": 190528 },
           { "type": 3, "cnt": 2978, "size": 309712 },
           { "type": 16, "cnt": 11912, "size": 95296 },
           { "type": 13, "cnt": 2, "size": 16 }] }] },
  { "function": { "point": 14048, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 128, "isize": 0,
       "dtype": [
           { "type": 30, "cnt": 1, "size": 48 },
           { "type": 3, "cnt": 1, "size": 64 },
           { "type": 13, "cnt": 2, "size": 16 }] ,
       "itype": [] },
     { "gc": 2, "dsize": 128, "isize": 0,
       "dtype": [
           { "type": 30, "cnt": 1, "size": 48 },
           { "type": 3, "cnt": 1, "size": 64 },
           { "type": 13, "cnt": 2, "size": 16 }] ,
       "itype": [] }] },
  { "function": "for@maze.js:521", "allocs": [
     { "gc": 3, "dsize": 0, "isize": 2304,
       "dtype": [] ,
       "itype": [
           { "type": 334, "cnt": 32, "size": 2304 }] },
     { "gc": 2, "dsize": 1280, "isize": 7056,
       "dtype": [
           { "type": 0, "cnt": 80, "size": 1280 }] ,
       "itype": [
           { "type": 334, "cnt": 98, "size": 7056 }] }] },
  { "function": { "point": 804, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 69192, "isize": 0,
       "dtype": [
           { "type": 334, "cnt": 961, "size": 69192 }] ,
       "itype": [] },
     { "gc": 2, "dsize": 2132640, "isize": 0,
       "dtype": [
           { "type": 0, "cnt": 6, "size": 96 },
           { "type": 54, "cnt": 3, "size": 408 },
           { "type": 30, "cnt": 3, "size": 432 },
           { "type": 2, "cnt": 6, "size": 144 },
           { "type": 15, "cnt": 6, "size": 288 },
           { "type": 334, "cnt": 29601, "size": 2131272 }] ,
       "itype": [] }] },
  { "function": "Harr.prototype.href&:main@maz", "allocs": [
     { "gc": 2, "dsize": 320, "isize": 0,
       "dtype": [
           { "type": 0, "cnt": 20, "size": 320 }] ,
       "itype": [] }] },
  { "function": "for@maze.js:430", "allocs": [
     { "gc": 3, "dsize": 16384, "isize": 66744,
       "dtype": [
           { "type": 2, "cnt": 8, "size": 16384 }] ,
       "itype": [
           { "type": 334, "cnt": 927, "size": 66744 }] },
     { "gc": 2, "dsize": 525608, "isize": 2125832,
       "dtype": [
           { "type": 2, "cnt": 13, "size": 524328 },
           { "type": 0, "cnt": 80, "size": 1280 }] ,
       "itype": [
           { "type": 54, "cnt": 3, "size": 408 },
           { "type": 30, "cnt": 3, "size": 432 },
           { "type": 2, "cnt": 6, "size": 144 },
           { "type": 15, "cnt": 6, "size": 288 },
           { "type": 334, "cnt": 29502, "size": 2124144 },
           { "type": 0, "cnt": 26, "size": 416 }] }] },
  { "function": { "point": 4005, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 416, "isize": 85576,
       "dtype": [
           { "type": 0, "cnt": 20, "size": 320 },
           { "type": 336, "cnt": 1, "size": 96 }] ,
       "itype": [
           { "type": 2, "cnt": 8, "size": 16384 },
           { "type": 334, "cnt": 961, "size": 69192 }] },
     { "gc": 2, "dsize": 992, "isize": 2659848,
       "dtype": [
           { "type": 0, "cnt": 56, "size": 896 },
           { "type": 336, "cnt": 1, "size": 96 }] ,
       "itype": [
           { "type": 54, "cnt": 3, "size": 408 },
           { "type": 30, "cnt": 3, "size": 432 },
           { "type": 2, "cnt": 19, "size": 524472 },
           { "type": 15, "cnt": 6, "size": 288 },
           { "type": 334, "cnt": 29601, "size": 2131272 },
           { "type": 0, "cnt": 186, "size": 2976 }] }] },
  { "function": { "point": 485, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 72, "isize": 0,
       "dtype": [
           { "type": 334, "cnt": 1, "size": 72 }] ,
       "itype": [] },
     { "gc": 2, "dsize": 1440, "isize": 0,
       "dtype": [
           { "type": 0, "cnt": 6, "size": 96 },
           { "type": 54, "cnt": 3, "size": 408 },
           { "type": 30, "cnt": 3, "size": 432 },
           { "type": 2, "cnt": 6, "size": 144 },
           { "type": 15, "cnt": 6, "size": 288 },
           { "type": 334, "cnt": 1, "size": 72 }] ,
       "itype": [] }] },
  { "function": { "point": 1047, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 30800, "isize": 0,
       "dtype": [
           { "type": 334, "cnt": 350, "size": 30800 }] ,
       "itype": [] },
     { "gc": 2, "dsize": 882360, "isize": 0,
       "dtype": [
           { "type": 0, "cnt": 10, "size": 160 },
           { "type": 54, "cnt": 5, "size": 680 },
           { "type": 30, "cnt": 5, "size": 720 },
           { "type": 2, "cnt": 10, "size": 320 },
           { "type": 15, "cnt": 10, "size": 480 },
           { "type": 334, "cnt": 10000, "size": 880000 }] ,
       "itype": [] }] },
  { "function": "for@maze.js:281", "allocs": [
     { "gc": 3, "dsize": 0, "isize": 75600,
       "dtype": [] ,
       "itype": [
           { "type": 334, "cnt": 1050, "size": 75600 }] },
     { "gc": 2, "dsize": 0, "isize": 2163256,
       "dtype": [] ,
       "itype": [
           { "type": 0, "cnt": 14, "size": 224 },
           { "type": 54, "cnt": 7, "size": 952 },
           { "type": 30, "cnt": 7, "size": 1008 },
           { "type": 2, "cnt": 14, "size": 400 },
           { "type": 15, "cnt": 14, "size": 672 },
           { "type": 334, "cnt": 30000, "size": 2160000 }] }] },
  { "function": { "point": 120, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 44800, "isize": 0,
       "dtype": [
           { "type": 334, "cnt": 700, "size": 44800 }] ,
       "itype": [] },
     { "gc": 2, "dsize": 1280896, "isize": 0,
       "dtype": [
           { "type": 0, "cnt": 4, "size": 64 },
           { "type": 54, "cnt": 2, "size": 272 },
           { "type": 30, "cnt": 2, "size": 288 },
           { "type": 2, "cnt": 4, "size": 80 },
           { "type": 15, "cnt": 4, "size": 192 },
           { "type": 334, "cnt": 20000, "size": 1280000 }] ,
       "itype": [] }] },
  { "function": { "point": 2724, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 2864, "isize": 75672,
       "dtype": [
           { "type": 2, "cnt": 1, "size": 2808 },
           { "type": 30, "cnt": 1, "size": 56 }] ,
       "itype": [
           { "type": 334, "cnt": 1051, "size": 75672 }] },
     { "gc": 2, "dsize": 80064, "isize": 2164696,
       "dtype": [
           { "type": 2, "cnt": 1, "size": 80008 },
           { "type": 30, "cnt": 1, "size": 56 }] ,
       "itype": [
           { "type": 0, "cnt": 20, "size": 320 },
           { "type": 54, "cnt": 10, "size": 1360 },
           { "type": 30, "cnt": 10, "size": 1440 },
           { "type": 2, "cnt": 20, "size": 544 },
           { "type": 15, "cnt": 20, "size": 960 },
           { "type": 334, "cnt": 30001, "size": 2160072 }] }] },
  { "function": "while:maze.j", "allocs": [
     { "gc": 3, "dsize": 0, "isize": 8529264,
       "dtype": [] ,
       "itype": [
           { "type": 30, "cnt": 10001, "size": 1360136 },
           { "type": 2, "cnt": 10001, "size": 480048 },
           { "type": 0, "cnt": 282, "size": 4512 },
           { "type": 13, "cnt": 2, "size": 16 },
           { "type": 3, "cnt": 36624, "size": 3568744 },
           { "type": 16, "cnt": 106484, "size": 851872 },
           { "type": 334, "cnt": 36624, "size": 2263936 }] },
     { "gc": 2, "dsize": 0, "isize": 5501736,
       "dtype": [] ,
       "itype": [
           { "type": 16, "cnt": 11912, "size": 95296 },
           { "type": 13, "cnt": 4, "size": 32 },
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 0, "cnt": 284, "size": 4544 },
           { "type": 54, "cnt": 13, "size": 1768 },
           { "type": 15, "cnt": 26, "size": 1248 },
           { "type": 334, "cnt": 62579, "size": 4481872 },
           { "type": 2, "cnt": 40, "size": 605024 },
           { "type": 30, "cnt": 15, "size": 1976 },
           { "type": 3, "cnt": 2981, "size": 309880 }] }] },
  { "function": { "point": 8284, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 784, "isize": 8996568,
       "dtype": [
           { "type": 334, "cnt": 2, "size": 144 },
           { "type": 0, "cnt": 40, "size": 640 }] ,
       "itype": [
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 30, "cnt": 10354, "size": 1407976 },
           { "type": 2, "cnt": 10361, "size": 516088 },
           { "type": 0, "cnt": 204, "size": 3264 },
           { "type": 13, "cnt": 8, "size": 64 },
           { "type": 3, "cnt": 37938, "size": 3696760 },
           { "type": 16, "cnt": 110320, "size": 882560 },
           { "type": 334, "cnt": 39945, "size": 2489760 }] },
     { "gc": 2, "dsize": 0, "isize": 5501736,
       "dtype": [] ,
       "itype": [
           { "type": 16, "cnt": 11912, "size": 95296 },
           { "type": 13, "cnt": 4, "size": 32 },
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 0, "cnt": 284, "size": 4544 },
           { "type": 54, "cnt": 13, "size": 1768 },
           { "type": 15, "cnt": 26, "size": 1248 },
           { "type": 334, "cnt": 62579, "size": 4481872 },
           { "type": 2, "cnt": 40, "size": 605024 },
           { "type": 30, "cnt": 15, "size": 1976 },
           { "type": 3, "cnt": 2981, "size": 309880 }] }] },
  { "function": { "point": 3851, "file": "maze.js" }, "allocs": [
     { "gc": 3, "dsize": 56, "isize": 78536,
       "dtype": [
           { "type": 3, "cnt": 1, "size": 56 }] ,
       "itype": [
           { "type": 334, "cnt": 1051, "size": 75672 },
           { "type": 2, "cnt": 1, "size": 2808 },
           { "type": 30, "cnt": 1, "size": 56 }] },
     { "gc": 2, "dsize": 56, "isize": 2244760,
       "dtype": [
           { "type": 3, "cnt": 1, "size": 56 }] ,
       "itype": [
           { "type": 0, "cnt": 20, "size": 320 },
           { "type": 54, "cnt": 10, "size": 1360 },
           { "type": 15, "cnt": 20, "size": 960 },
           { "type": 334, "cnt": 30001, "size": 2160072 },
           { "type": 2, "cnt": 21, "size": 80552 },
           { "type": 30, "cnt": 11, "size": 1496 }] }] },
  { "function": { "point": 17192, "file": "maze.js" }, "allocs": [
     { "gc": 4, "dsize": 0, "isize": 418776,
       "dtype": [] ,
       "itype": [
           { "type": 30, "cnt": 1302, "size": 144088 },
           { "type": 2, "cnt": 1302, "size": 36456 },
           { "type": 3, "cnt": 1304, "size": 74800 },
           { "type": 0, "cnt": 4778, "size": 76448 },
           { "type": 13, "cnt": 2610, "size": 20880 },
           { "type": 334, "cnt": 1087, "size": 66104 }] },
     { "gc": 3, "dsize": 0, "isize": 11569072,
       "dtype": [] ,
       "itype": [
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 30, "cnt": 18329, "size": 2290480 },
           { "type": 2, "cnt": 18339, "size": 739472 },
           { "type": 0, "cnt": 30078, "size": 481248 },
           { "type": 13, "cnt": 15950, "size": 127600 },
           { "type": 3, "cnt": 45911, "size": 4153832 },
           { "type": 16, "cnt": 110320, "size": 882560 },
           { "type": 334, "cnt": 46590, "size": 2893784 }] },
     { "gc": 2, "dsize": 0, "isize": 5512191,
       "dtype": [] ,
       "itype": [
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 54, "cnt": 17, "size": 2312 },
           { "type": 15, "cnt": 34, "size": 1632 },
           { "type": 330, "cnt": 1, "size": 48 },
           { "type": 1, "cnt": 9, "size": 287 },
           { "type": 3, "cnt": 2993, "size": 310560 },
           { "type": 13, "cnt": 30, "size": 240 },
           { "type": 334, "cnt": 62589, "size": 4482456 },
           { "type": 30, "cnt": 47, "size": 4776 },
           { "type": 2, "cnt": 72, "size": 605944 },
           { "type": 0, "cnt": 530, "size": 8480 },
           { "type": 331, "cnt": 1, "size": 48 },
           { "type": 16, "cnt": 11914, "size": 95312 }] }] },
  { "function": { "point": 17192, "file": "maze.js" }, "allocs": [
     { "gc": 4, "dsize": 0, "isize": 418776,
       "dtype": [] ,
       "itype": [
           { "type": 30, "cnt": 1302, "size": 144088 },
           { "type": 2, "cnt": 1302, "size": 36456 },
           { "type": 3, "cnt": 1304, "size": 74800 },
           { "type": 0, "cnt": 4778, "size": 76448 },
           { "type": 13, "cnt": 2610, "size": 20880 },
           { "type": 334, "cnt": 1087, "size": 66104 }] },
     { "gc": 3, "dsize": 0, "isize": 11569072,
       "dtype": [] ,
       "itype": [
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 30, "cnt": 18329, "size": 2290480 },
           { "type": 2, "cnt": 18339, "size": 739472 },
           { "type": 0, "cnt": 30078, "size": 481248 },
           { "type": 13, "cnt": 15950, "size": 127600 },
           { "type": 3, "cnt": 45911, "size": 4153832 },
           { "type": 16, "cnt": 110320, "size": 882560 },
           { "type": 334, "cnt": 46590, "size": 2893784 }] },
     { "gc": 2, "dsize": 10407, "isize": 5501784,
       "dtype": [
           { "type": 54, "cnt": 4, "size": 544 },
           { "type": 15, "cnt": 8, "size": 384 },
           { "type": 1, "cnt": 9, "size": 287 },
           { "type": 3, "cnt": 12, "size": 680 },
           { "type": 13, "cnt": 26, "size": 208 },
           { "type": 334, "cnt": 10, "size": 584 },
           { "type": 30, "cnt": 32, "size": 2800 },
           { "type": 2, "cnt": 32, "size": 920 },
           { "type": 0, "cnt": 246, "size": 3936 },
           { "type": 331, "cnt": 1, "size": 48 },
           { "type": 16, "cnt": 2, "size": 16 }] ,
       "itype": [
           { "type": 16, "cnt": 11912, "size": 95296 },
           { "type": 13, "cnt": 4, "size": 32 },
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 0, "cnt": 284, "size": 4544 },
           { "type": 54, "cnt": 13, "size": 1768 },
           { "type": 15, "cnt": 26, "size": 1248 },
           { "type": 334, "cnt": 62579, "size": 4481872 },
           { "type": 2, "cnt": 40, "size": 605024 },
           { "type": 30, "cnt": 15, "size": 1976 },
           { "type": 3, "cnt": 2981, "size": 309880 },
           { "type": 330, "cnt": 1, "size": 48 }] }] },
  { "function": "#:main@maz", "allocs": [
     { "gc": 4, "dsize": 0, "isize": 418776,
       "dtype": [] ,
       "itype": [
           { "type": 30, "cnt": 1302, "size": 144088 },
           { "type": 2, "cnt": 1302, "size": 36456 },
           { "type": 3, "cnt": 1304, "size": 74800 },
           { "type": 0, "cnt": 4778, "size": 76448 },
           { "type": 13, "cnt": 2610, "size": 20880 },
           { "type": 334, "cnt": 1087, "size": 66104 }] },
     { "gc": 3, "dsize": 0, "isize": 11569072,
       "dtype": [] ,
       "itype": [
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 30, "cnt": 18329, "size": 2290480 },
           { "type": 2, "cnt": 18339, "size": 739472 },
           { "type": 0, "cnt": 30078, "size": 481248 },
           { "type": 13, "cnt": 15950, "size": 127600 },
           { "type": 3, "cnt": 45911, "size": 4153832 },
           { "type": 16, "cnt": 110320, "size": 882560 },
           { "type": 334, "cnt": 46590, "size": 2893784 }] },
     { "gc": 2, "dsize": 53563, "isize": 5512527,
       "dtype": [
           { "type": 329, "cnt": 1, "size": 144 },
           { "type": 334, "cnt": 72, "size": 4088 },
           { "type": 3, "cnt": 102, "size": 5624 },
           { "type": 15, "cnt": 50, "size": 2224 },
           { "type": 54, "cnt": 25, "size": 3400 },
           { "type": 0, "cnt": 192, "size": 3072 },
           { "type": 30, "cnt": 163, "size": 17872 },
           { "type": 1, "cnt": 100, "size": 2907 },
           { "type": 2, "cnt": 193, "size": 13176 },
           { "type": 13, "cnt": 132, "size": 1056 }] ,
       "itype": [
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 54, "cnt": 17, "size": 2312 },
           { "type": 15, "cnt": 34, "size": 1632 },
           { "type": 1, "cnt": 9, "size": 287 },
           { "type": 3, "cnt": 2993, "size": 310560 },
           { "type": 13, "cnt": 30, "size": 240 },
           { "type": 334, "cnt": 62589, "size": 4482456 },
           { "type": 30, "cnt": 47, "size": 4776 },
           { "type": 2, "cnt": 72, "size": 605944 },
           { "type": 0, "cnt": 530, "size": 8480 },
           { "type": 331, "cnt": 1, "size": 48 },
           { "type": 16, "cnt": 11914, "size": 95312 },
           { "type": 330, "cnt": 8, "size": 384 }] }] },
  { "function": "new RegEx", "allocs": [
     { "gc": 2, "dsize": 2075, "isize": 0,
       "dtype": [
           { "type": 2, "cnt": 4, "size": 64 },
           { "type": 365, "cnt": 4, "size": 256 },
           { "type": 45, "cnt": 4, "size": 256 },
           { "type": 1, "cnt": 6, "size": 251 },
           { "type": 0, "cnt": 40, "size": 640 },
           { "type": 3, "cnt": 8, "size": 416 },
           { "type": 13, "cnt": 24, "size": 192 }] ,
       "itype": [] },
     { "gc": 1, "dsize": 6402, "isize": 0,
       "dtype": [
           { "type": 2, "cnt": 12, "size": 192 },
           { "type": 365, "cnt": 12, "size": 768 },
           { "type": 45, "cnt": 12, "size": 768 },
           { "type": 1, "cnt": 18, "size": 930 },
           { "type": 0, "cnt": 120, "size": 1920 },
           { "type": 3, "cnt": 24, "size": 1248 },
           { "type": 13, "cnt": 72, "size": 576 }] ,
       "itype": [] }] },
  { "function": "vector->jsarra", "allocs": [
     { "gc": 2, "dsize": 1456, "isize": 0,
       "dtype": [
           { "type": 336, "cnt": 26, "size": 1456 }] ,
       "itype": [] },
     { "gc": 1, "dsize": 2688, "isize": 0,
       "dtype": [
           { "type": 336, "cnt": 48, "size": 2688 }] ,
       "itype": [] }] },
  { "function": "js-string->jsstrin", "allocs": [
     { "gc": 2, "dsize": 8880, "isize": 0,
       "dtype": [
           { "type": 330, "cnt": 185, "size": 8880 }] ,
       "itype": [] },
     { "gc": 1, "dsize": 13344, "isize": 0,
       "dtype": [
           { "type": 330, "cnt": 278, "size": 13344 }] ,
       "itype": [] }] },
  { "function": "&pthread-103", "allocs": [
     { "gc": 4, "dsize": 520, "isize": 418776,
       "dtype": [
           { "type": 3, "cnt": 2, "size": 104 },
           { "type": 13, "cnt": 2, "size": 16 },
           { "type": 2, "cnt": 1, "size": 48 },
           { "type": 0, "cnt": 22, "size": 352 }] ,
       "itype": [
           { "type": 30, "cnt": 1302, "size": 144088 },
           { "type": 2, "cnt": 1302, "size": 36456 },
           { "type": 3, "cnt": 1304, "size": 74800 },
           { "type": 0, "cnt": 4778, "size": 76448 },
           { "type": 13, "cnt": 2610, "size": 20880 },
           { "type": 334, "cnt": 1087, "size": 66104 }] },
     { "gc": 3, "dsize": 0, "isize": 11569072,
       "dtype": [] ,
       "itype": [
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 30, "cnt": 18329, "size": 2290480 },
           { "type": 2, "cnt": 18339, "size": 739472 },
           { "type": 0, "cnt": 30078, "size": 481248 },
           { "type": 13, "cnt": 15950, "size": 127600 },
           { "type": 3, "cnt": 45911, "size": 4153832 },
           { "type": 16, "cnt": 110320, "size": 882560 },
           { "type": 334, "cnt": 46590, "size": 2893784 }] },
     { "gc": 2, "dsize": 1349757, "isize": 5578117,
       "dtype": [
           { "type": 336, "cnt": 4, "size": 384 },
           { "type": 99, "cnt": 11, "size": 15800 },
           { "type": 1, "cnt": 1309, "size": 40725 },
           { "type": 15, "cnt": 1015, "size": 46904 },
           { "type": 54, "cnt": 494, "size": 67184 },
           { "type": 334, "cnt": 1126, "size": 65760 },
           { "type": 3, "cnt": 1181, "size": 69064 },
           { "type": 0, "cnt": 3780, "size": 60480 },
           { "type": 2, "cnt": 3026, "size": 248304 },
           { "type": 13, "cnt": 938, "size": 7504 },
           { "type": 30, "cnt": 4948, "size": 727648 }] ,
       "itype": [
           { "type": 331, "cnt": 1, "size": 48 },
           { "type": 16, "cnt": 11914, "size": 95312 },
           { "type": 329, "cnt": 1, "size": 144 },
           { "type": 334, "cnt": 62661, "size": 4486544 },
           { "type": 15, "cnt": 84, "size": 3856 },
           { "type": 54, "cnt": 42, "size": 5712 },
           { "type": 30, "cnt": 210, "size": 22648 },
           { "type": 2, "cnt": 269, "size": 619184 },
           { "type": 365, "cnt": 4, "size": 256 },
           { "type": 45, "cnt": 4, "size": 256 },
           { "type": 1, "cnt": 115, "size": 3445 },
           { "type": 0, "cnt": 762, "size": 12192 },
           { "type": 3, "cnt": 3103, "size": 316600 },
           { "type": 13, "cnt": 186, "size": 1488 },
           { "type": 336, "cnt": 27, "size": 1552 },
           { "type": 330, "cnt": 185, "size": 8880 }] },
     { "gc": 1, "dsize": 2820155, "isize": 22434,
       "dtype": [
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 51, "cnt": 1, "size": 16 },
           { "type": 53, "cnt": 1, "size": 136 },
           { "type": 12, "cnt": 1, "size": 64 },
           { "type": 45, "cnt": 1, "size": 64 },
           { "type": 16, "cnt": 24, "size": 192 },
           { "type": 99, "cnt": 23, "size": 32112 },
           { "type": 1, "cnt": 3170, "size": 102014 },
           { "type": 15, "cnt": 2084, "size": 92896 },
           { "type": 2, "cnt": 6312, "size": 922544 },
           { "type": 334, "cnt": 1558, "size": 91344 },
           { "type": 8, "cnt": 14, "size": 560 },
           { "type": 31, "cnt": 141, "size": 3797 },
           { "type": 54, "cnt": 732, "size": 99552 },
           { "type": 30, "cnt": 8671, "size": 1146592 },
           { "type": 0, "cnt": 13636, "size": 218176 },
           { "type": 13, "cnt": 1438, "size": 11504 },
           { "type": 3, "cnt": 1773, "size": 98496 }] ,
       "itype": [
           { "type": 2, "cnt": 12, "size": 192 },
           { "type": 365, "cnt": 12, "size": 768 },
           { "type": 45, "cnt": 12, "size": 768 },
           { "type": 1, "cnt": 18, "size": 930 },
           { "type": 0, "cnt": 120, "size": 1920 },
           { "type": 3, "cnt": 24, "size": 1248 },
           { "type": 13, "cnt": 72, "size": 576 },
           { "type": 336, "cnt": 48, "size": 2688 },
           { "type": 330, "cnt": 278, "size": 13344 }] }] },
  { "function": "main@maz", "allocs": [
     { "gc": 1, "dsize": 75988, "isize": 0,
       "dtype": [
           { "type": 29, "cnt": 2, "size": 696 },
           { "type": 2, "cnt": 1, "size": 264 },
           { "type": 55, "cnt": 2, "size": 112 },
           { "type": 53, "cnt": 2, "size": 272 },
           { "type": 8, "cnt": 4, "size": 160 },
           { "type": 3, "cnt": 591, "size": 31792 },
           { "type": 30, "cnt": 350, "size": 22104 },
           { "type": 54, "cnt": 2, "size": 272 },
           { "type": 11, "cnt": 2, "size": 320 },
           { "type": 1, "cnt": 13, "size": 700 },
           { "type": 0, "cnt": 1206, "size": 19296 }] ,
       "itype": [] }] },
  { "function": "%resource@maz", "allocs": [
     { "gc": 1, "dsize": 28, "isize": 0,
       "dtype": [
           { "type": 1, "cnt": 1, "size": 28 }] ,
       "itype": [] }] },
  { "function": "%toplevel@maz", "allocs": [
     { "gc": 1, "dsize": 0, "isize": 324,
       "dtype": [] ,
       "itype": [
           { "type": 1, "cnt": 1, "size": 28 },
           { "type": 0, "cnt": 4, "size": 64 },
           { "type": 30, "cnt": 1, "size": 48 },
           { "type": 328, "cnt": 1, "size": 184 }] }] },
  { "function": "%pcache@maz", "allocs": [
     { "gc": 1, "dsize": 296, "isize": 0,
       "dtype": [
           { "type": 0, "cnt": 4, "size": 64 },
           { "type": 30, "cnt": 1, "size": 48 },
           { "type": 328, "cnt": 1, "size": 184 }] ,
       "itype": [] }] },
  { "function": "eval-init@maz", "allocs": [
     { "gc": 1, "dsize": 964498, "isize": 0,
       "dtype": [
           { "type": 45, "cnt": 12, "size": 768 },
           { "type": 53, "cnt": 5, "size": 680 },
           { "type": 99, "cnt": 20, "size": 4000 },
           { "type": 52, "cnt": 14, "size": 2800 },
           { "type": 7, "cnt": 20, "size": 480 },
           { "type": 2, "cnt": 2082, "size": 105048 },
           { "type": 3, "cnt": 861, "size": 45920 },
           { "type": 0, "cnt": 13740, "size": 219840 },
           { "type": 8, "cnt": 1721, "size": 68840 },
           { "type": 31, "cnt": 1716, "size": 72186 },
           { "type": 30, "cnt": 2508, "size": 160776 },
           { "type": 13, "cnt": 29988, "size": 239904 },
           { "type": 10, "cnt": 18, "size": 3168 },
           { "type": 1, "cnt": 1012, "size": 40088 }] ,
       "itype": [] }] },
  { "function": "unknown_functio", "allocs": [
     { "gc": 4, "dsize": 0, "isize": 419296,
       "dtype": [] ,
       "itype": [
           { "type": 30, "cnt": 1302, "size": 144088 },
           { "type": 2, "cnt": 1303, "size": 36504 },
           { "type": 3, "cnt": 1306, "size": 74904 },
           { "type": 0, "cnt": 4800, "size": 76800 },
           { "type": 13, "cnt": 2612, "size": 20896 },
           { "type": 334, "cnt": 1087, "size": 66104 }] },
     { "gc": 3, "dsize": 0, "isize": 11569072,
       "dtype": [] ,
       "itype": [
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 30, "cnt": 18329, "size": 2290480 },
           { "type": 2, "cnt": 18339, "size": 739472 },
           { "type": 0, "cnt": 30078, "size": 481248 },
           { "type": 13, "cnt": 15950, "size": 127600 },
           { "type": 3, "cnt": 45911, "size": 4153832 },
           { "type": 16, "cnt": 110320, "size": 882560 },
           { "type": 334, "cnt": 46590, "size": 2893784 }] },
     { "gc": 2, "dsize": 0, "isize": 6927874,
       "dtype": [] ,
       "itype": [
           { "type": 331, "cnt": 1, "size": 48 },
           { "type": 16, "cnt": 11914, "size": 95312 },
           { "type": 329, "cnt": 1, "size": 144 },
           { "type": 365, "cnt": 4, "size": 256 },
           { "type": 45, "cnt": 4, "size": 256 },
           { "type": 99, "cnt": 11, "size": 15800 },
           { "type": 336, "cnt": 31, "size": 1936 },
           { "type": 1, "cnt": 1424, "size": 44170 },
           { "type": 15, "cnt": 1099, "size": 50760 },
           { "type": 330, "cnt": 185, "size": 8880 },
           { "type": 54, "cnt": 536, "size": 72896 },
           { "type": 334, "cnt": 63787, "size": 4552304 },
           { "type": 3, "cnt": 4284, "size": 385664 },
           { "type": 0, "cnt": 4542, "size": 72672 },
           { "type": 2, "cnt": 3295, "size": 867488 },
           { "type": 13, "cnt": 1124, "size": 8992 },
           { "type": 30, "cnt": 5158, "size": 750296 }] },
     { "gc": 1, "dsize": 726446, "isize": 3883399,
       "dtype": [
           { "type": 55, "cnt": 1, "size": 56 },
           { "type": 15, "cnt": 3, "size": 264 },
           { "type": 53, "cnt": 4, "size": 544 },
           { "type": 8, "cnt": 136, "size": 5440 },
           { "type": 31, "cnt": 130, "size": 7017 },
           { "type": 10, "cnt": 27, "size": 4752 },
           { "type": 2, "cnt": 25, "size": 3296 },
           { "type": 1, "cnt": 1529, "size": 337125 },
           { "type": 0, "cnt": 12394, "size": 198304 },
           { "type": 30, "cnt": 1062, "size": 67904 },
           { "type": 13, "cnt": 12718, "size": 101744 }] ,
       "itype": [
           { "type": 365, "cnt": 12, "size": 768 },
           { "type": 51, "cnt": 1, "size": 16 },
           { "type": 336, "cnt": 49, "size": 2784 },
           { "type": 330, "cnt": 278, "size": 13344 },
           { "type": 12, "cnt": 1, "size": 64 },
           { "type": 16, "cnt": 24, "size": 192 },
           { "type": 15, "cnt": 2084, "size": 92896 },
           { "type": 334, "cnt": 1558, "size": 91344 },
           { "type": 29, "cnt": 2, "size": 696 },
           { "type": 55, "cnt": 2, "size": 112 },
           { "type": 54, "cnt": 734, "size": 99824 },
           { "type": 11, "cnt": 2, "size": 320 },
           { "type": 328, "cnt": 1, "size": 184 },
           { "type": 45, "cnt": 25, "size": 1600 },
           { "type": 53, "cnt": 8, "size": 1088 },
           { "type": 99, "cnt": 43, "size": 36112 },
           { "type": 52, "cnt": 14, "size": 2800 },
           { "type": 7, "cnt": 20, "size": 480 },
           { "type": 2, "cnt": 8407, "size": 1028048 },
           { "type": 3, "cnt": 3249, "size": 177456 },
           { "type": 0, "cnt": 28706, "size": 459296 },
           { "type": 8, "cnt": 1739, "size": 69560 },
           { "type": 31, "cnt": 1857, "size": 75983 },
           { "type": 30, "cnt": 11530, "size": 1329520 },
           { "type": 13, "cnt": 31498, "size": 251984 },
           { "type": 10, "cnt": 18, "size": 3168 },
           { "type": 1, "cnt": 4214, "size": 143760 }] },
     { "gc": 0, "dsize": 4497507, "isize": 0,
       "dtype": [
           { "type": 56, "cnt": 8, "size": 192 },
           { "type": 54, "cnt": 13, "size": 1768 },
           { "type": 11, "cnt": 6, "size": 960 },
           { "type": 12, "cnt": 3, "size": 192 },
           { "type": 45, "cnt": 50, "size": 3200 },
           { "type": 26, "cnt": 39, "size": 624 },
           { "type": 25, "cnt": 7, "size": 112 },
           { "type": 3, "cnt": 943, "size": 52080 },
           { "type": 15, "cnt": 120, "size": 9448 },
           { "type": 13, "cnt": 96162, "size": 769296 },
           { "type": 10, "cnt": 224, "size": 39424 },
           { "type": 55, "cnt": 2, "size": 112 },
           { "type": 53, "cnt": 51, "size": 6880 },
           { "type": 30, "cnt": 8648, "size": 540196 },
           { "type": 7, "cnt": 554, "size": 13296 },
           { "type": 52, "cnt": 457, "size": 91400 },
           { "type": 99, "cnt": 1267, "size": 235608 },
           { "type": 2, "cnt": 7292, "size": 639456 },
           { "type": 1, "cnt": 4016, "size": 265727 },
           { "type": 0, "cnt": 76928, "size": 1230848 },
           { "type": 8, "cnt": 7079, "size": 283160 },
           { "type": 31, "cnt": 7094, "size": 260544 }] ,
       "itype": [] }] }]
}}'
]

{ #category : #running }
HopTraceExample >> run [
	<script: 'self new run inspect'>
	| m |
	m := HTVModel new.
	m parseTraceJSONAsText: HopTraceExample new traceExample.
	^ m
]

{ #category : #'as yet unclassified' }
HopTraceExample >> traceExample [

^ '{
"format": "memviz",
"version": "0.0.1",
"calls": [
 { "filename": "maze.js",
   "calls": [
     { "point": 791, "cnt": [ { "target": 617, "cnt": 15842619 } ] },
     { "point": 2938, "cnt": [ { "target": 3913, "cnt": 2000350 } ] },
     { "point": 3905, "cnt": 201, "target": 2724 },
     { "point": 3939, "cnt": 2000350, "target": 15923 },
     { "point": 3950, "cnt": 2000350, "target": 422 },
     { "point": 4476, "cnt": [ { "target": 704, "cnt": 1980315 } ] },
     { "point": 4510, "cnt": 1960506, "target": 4165 },
     { "point": 4526, "cnt": [ { "target": 704, "cnt": 1960506 } ] },
     { "point": 4566, "cnt": 1980315, "target": 4165 },
     { "point": 4582, "cnt": [ { "target": 704, "cnt": 1980315 } ] },
     { "point": 4629, "cnt": 1960506, "target": 4165 },
     { "point": 4645, "cnt": [ { "target": 704, "cnt": 1960506 } ] },
     { "point": 5000, "cnt": [ { "target": 704, "cnt": 201 } ] },
     { "point": 5081, "cnt": 1, "target": 4165 },
     { "point": 5101, "cnt": [ { "target": 704, "cnt": 1 } ] },
     { "point": 5148, "cnt": 201, "target": 4165 },
     { "point": 5168, "cnt": [ { "target": 704, "cnt": 201 } ] },
     { "point": 5266, "cnt": 9816, "target": 4165 },
     { "point": 5277, "cnt": [ { "target": 704, "cnt": 9816 } ] },
     { "point": 5296, "cnt": [ { "target": 704, "cnt": 9816 } ] },
     { "point": 5332, "cnt": 9816, "target": 4165 },
     { "point": 5343, "cnt": [ { "target": 704, "cnt": 9816 } ] },
     { "point": 5362, "cnt": [ { "target": 704, "cnt": 9816 } ] },
     { "point": 5804, "cnt": 201, "target": 12928 },
     { "point": 5823, "cnt": [ { "target": 617, "cnt": 201 } ] },
     { "point": 6150, "cnt": [ { "target": 617, "cnt": 20035 } ] },
     { "point": 6183, "cnt": 20035, "target": 13216 },
     { "point": 6544, "cnt": 2001225, "target": 13471 },
     { "point": 6557, "cnt": [ { "target": 617, "cnt": 2001225 } ] },
     { "point": 6621, "cnt": 2212, "target": 6198 },
     { "point": 6687, "cnt": 1999013, "target": 6198 },
     { "point": 6788, "cnt": 20035, "target": 6198 },
     { "point": 6840, "cnt": 20035, "target": 5856 },
     { "point": 6902, "cnt": 201, "target": 5856 },
     { "point": 7250, "cnt": 2000350, "target": 10847 },
     { "point": 7277, "cnt": [ { "target": 13063, "cnt": 671728 } ] },
     { "point": 7288, "cnt": [ { "target": 704, "cnt": 671728 } ] },
     { "point": 7323, "cnt": 2000350, "target": 10847 },
     { "point": 7346, "cnt": [ { "target": 13063, "cnt": 658891 } ] },
     { "point": 7357, "cnt": [ { "target": 704, "cnt": 658891 } ] },
     { "point": 7388, "cnt": 2000350, "target": 10847 },
     { "point": 7415, "cnt": [ { "target": 13063, "cnt": 669530 } ] },
     { "point": 7426, "cnt": [ { "target": 704, "cnt": 669530 } ] },
     { "point": 7677, "cnt": [ { "target": 704, "cnt": 1970323 } ] },
     { "point": 7713, "cnt": 1970323, "target": 10847 },
     { "point": 7743, "cnt": [ { "target": 13063, "cnt": 669530 } ] },
     { "point": 7876, "cnt": [ { "target": 704, "cnt": 1980315 } ] },
     { "point": 7908, "cnt": 1980315, "target": 10847 },
     { "point": 7933, "cnt": [ { "target": 13063, "cnt": 658891 } ] },
     { "point": 8185, "cnt": [ { "target": 704, "cnt": 1970523 } ] },
     { "point": 8221, "cnt": 1970523, "target": 10847 },
     { "point": 8251, "cnt": [ { "target": 13063, "cnt": 671728 } ] },
     { "point": 8346, "cnt": 201, "target": 3851 },
     { "point": 8389, "cnt": 201, "target": 11519 },
     { "point": 8402, "cnt": 201, "target": 4005 },
     { "point": 8423, "cnt": 201, "target": 14048 },
     { "point": 8444, "cnt": 201, "target": 11908 },
     { "point": 8512, "cnt": 201, "target": 5703 },
     { "point": 8551, "cnt": [ { "target": 617, "cnt": 201 } ] },
     { "point": 8609, "cnt": 201, "target": 13216 },
     { "point": 8622, "cnt": [ { "target": 617, "cnt": 201 } ] },
     { "point": 8660, "cnt": 201, "target": 13682 },
     { "point": 8824, "cnt": 201, "target": 8284 },
     { "point": 8858, "cnt": 201, "target": 9241 },
     { "point": 9488, "cnt": 10017, "target": 16988 },
     { "point": 9514, "cnt": 10017, "target": 17082 },
     { "point": 9561, "cnt": 201, "target": 17141 },
     { "point": 9691, "cnt": 201, "target": 17082 },
     { "point": 9759, "cnt": 10017, "target": 16988 },
     { "point": 9804, "cnt": 10017, "target": 16988 },
     { "point": 9826, "cnt": 10017, "target": 16988 },
     { "point": 9836, "cnt": 10017, "target": 11008 },
     { "point": 9879, "cnt": 10017, "target": 16988 },
     { "point": 9923, "cnt": 1, "target": 17082 },
     { "point": 9975, "cnt": 201, "target": 17141 },
     { "point": 10086, "cnt": 20010, "target": 17082 },
     { "point": 10206, "cnt": 1000170, "target": 17082 },
     { "point": 10216, "cnt": 1000170, "target": 11008 },
     { "point": 10256, "cnt": 1000170, "target": 11134 },
     { "point": 10269, "cnt": [ { "target": 617, "cnt": 1000170 } ] },
     { "point": 10331, "cnt": 10, "target": 17082 },
     { "point": 10341, "cnt": 10, "target": 11008 },
     { "point": 10378, "cnt": 10, "target": 17082 },
     { "point": 10410, "cnt": 20010, "target": 17141 },
     { "point": 10529, "cnt": 1000170, "target": 11134 },
     { "point": 10542, "cnt": [ { "target": 617, "cnt": 1000170 } ] },
     { "point": 10637, "cnt": 1000170, "target": 17082 },
     { "point": 10647, "cnt": 1000170, "target": 11008 },
     { "point": 10724, "cnt": 10, "target": 11134 },
     { "point": 10737, "cnt": [ { "target": 617, "cnt": 10 } ] },
     { "point": 10803, "cnt": 19800, "target": 17082 },
     { "point": 10835, "cnt": 20010, "target": 17141 },
     { "point": 11075, "cnt": [ { "target": 617, "cnt": 2000350 } ] },
     { "point": 11186, "cnt": 2000350, "target": 17082 },
     { "point": 11195, "cnt": 2000350, "target": 10847 },
     { "point": 11247, "cnt": 2000350, "target": 17082 },
     { "point": 11256, "cnt": 2000350, "target": 10847 },
     { "point": 11303, "cnt": 2000350, "target": 17082 },
     { "point": 11312, "cnt": 2000350, "target": 10847 },
     { "point": 11651, "cnt": 5920759, "target": 14500 },
     { "point": 11844, "cnt": [ { "target": 11976, "cnt": 5491482 } ] },
     { "point": 11974, "cnt": [ { "target": 11766, "cnt": 201 } ] },
     { "point": 12354, "cnt": 5491482, "target": 16554 },
     { "point": 12442, "cnt": 2000149, "target": 16694 },
     { "point": 12510, "cnt": 2000149, "target": 16636 },
     { "point": 13061, "cnt": [ { "target": 6984, "cnt": 2000350 } ] },
     { "point": 13105, "cnt": 2000149, "target": 12976 },
     { "point": 13167, "cnt": 201, "target": 12976 },
     { "point": 13375, "cnt": 383448, "target": 13252 },
     { "point": 13414, "cnt": 20236, "target": 13252 },
     { "point": 13760, "cnt": 125663, "target": 13682 },
     { "point": 14216, "cnt": 5920759, "target": 13978 },
     { "point": 14249, "cnt": 5920759, "target": 13978 },
     { "point": 14284, "cnt": 5920759, "target": 13978 },
     { "point": 14290, "cnt": 5920759, "target": 13978 },
     { "point": 14307, "cnt": 5920759, "target": 13978 },
     { "point": 14547, "cnt": 5920759, "target": 13978 },
     { "point": 14553, "cnt": 5920759, "target": 14417 },
     { "point": 15965, "cnt": 2000350, "target": 422 },
     { "point": 16245, "cnt": 14485072, "target": 16112 },
     { "point": 16459, "cnt": 2591948, "target": 16325 },
     { "point": 16494, "cnt": 11893124, "target": 16325 },
     { "point": 16544, "cnt": 20983709, "target": 16112 },
     { "point": 16604, "cnt": 5491482, "target": 16082 },
     { "point": 16625, "cnt": 5491482, "target": 16082 },
     { "point": 16680, "cnt": 6000447, "target": 16082 },
     { "point": 16743, "cnt": 2000149, "target": 16082 },
     { "point": 16773, "cnt": 2000149, "target": 16082 },
     { "point": 16800, "cnt": 2000149, "target": 16636 },
     { "point": 16827, "cnt": 2000149, "target": 16636 },
     { "point": 17128, "cnt": 8051439, "target": 16988 },
     { "point": 17179, "cnt": 40422, "target": 16988 },
     { "point": 17433, "cnt": 200, "target": 8749 },
     { "point": 17478, "cnt": 1, "target": 8749 },
     { "point": 17617, "cnt": 1, "target": 17192 } ] }
],
"symbols": [
 { "point": 215, "type": "fun", "name": "Cons.prototype.toString", "endpoint": 322 },
 { "point": 355, "type": "fun", "name": "Cons.prototype.toConsString", "endpoint": 419 },
 { "point": 422, "type": "fun", "name": "CONS", "endpoint": 482 },
 { "point": 485, "type": "fun", "name": "Harr", "endpoint": 590 },
 { "point": 617, "type": "fun", "name": "Harr.prototype.hrefRC", "endpoint": 679 },
 { "point": 704, "type": "fun", "name": "Harr.prototype.href", "endpoint": 801 },
 { "point": 804, "type": "fun", "name": "Wall", "endpoint": 1044 },
 { "point": 1047, "type": "fun", "name": "Box", "endpoint": 1484 },
 { "point": 2724, "type": "fun", "name": "harrTabulate", "endpoint": 3019 },
 { "point": 3851, "type": "fun", "name": "genMazeArray", "endpoint": 3964 },
 { "point": 3913, "type": "fun", "name": "%%anonymous", "endpoint": 3960 },
 { "point": 4005, "type": "fun", "name": "makeWallVec", "endpoint": 5430 },
 { "point": 4165, "type": "fun", "name": "addWall", "endpoint": 4261 },
 { "point": 5703, "type": "fun", "name": "pickEntrances", "endpoint": 6934 },
 { "point": 5856, "type": "fun", "name": "TPLP", "endpoint": 6885 },
 { "point": 6198, "type": "fun", "name": "BTLP", "endpoint": 6743 },
 { "point": 6984, "type": "fun", "name": "forEachHexChild", "endpoint": 8264 },
 { "point": 8284, "type": "fun", "name": "makeMaze", "endpoint": 8746 },
 { "point": 8749, "type": "fun", "name": "pmaze", "endpoint": 8878 },
 { "point": 9241, "type": "fun", "name": "printHexMaze", "endpoint": 10844 },
 { "point": 10847, "type": "fun", "name": "bitTest", "endpoint": 10903 },
 { "point": 11008, "type": "fun", "name": "dotSpace", "endpoint": 11104 },
 { "point": 11134, "type": "fun", "name": "displayHexBottom", "endpoint": 11351 },
 { "point": 11519, "type": "fun", "name": "permuteVec", "endpoint": 11734 },
 { "point": 11766, "type": "fun", "name": "Array.prototype.forEachRev", "endpoint": 11864 },
 { "point": 11908, "type": "fun", "name": "digMaze", "endpoint": 12636 },
 { "point": 11976, "type": "fun", "name": "%%anonymous", "endpoint": 12571 },
 { "point": 12928, "type": "fun", "name": "dfsMaze", "endpoint": 13184 },
 { "point": 12976, "type": "fun", "name": "search", "endpoint": 13148 },
 { "point": 13063, "type": "fun", "name": "%%anonymous", "endpoint": 13128 },
 { "point": 13216, "type": "fun", "name": "rerootMaze", "endpoint": 13434 },
 { "point": 13252, "type": "fun", "name": "lp", "endpoint": 13399 },
 { "point": 13471, "type": "fun", "name": "pathLength", "endpoint": 13606 },
 { "point": 13682, "type": "fun", "name": "markPath", "endpoint": 13777 },
 { "point": 13978, "type": "fun", "name": "fx28", "endpoint": 14030 },
 { "point": 14048, "type": "fun", "name": "randomState", "endpoint": 14075 },
 { "point": 14181, "type": "fun", "name": "%%anonymous", "endpoint": 14181 },
 { "point": 14181, "type": "fun", "name": "%%anonymous", "endpoint": 14181 },
 { "point": 14417, "type": "fun", "name": "rand", "endpoint": 14472 },
 { "point": 14500, "type": "fun", "name": "randomInt", "endpoint": 14570 },
 { "point": 15923, "type": "fun", "name": "baseSet", "endpoint": 15982 },
 { "point": 16082, "type": "fun", "name": "getSetRoot", "endpoint": 16551 },
 { "point": 16112, "type": "fun", "name": "lp", "endpoint": 16529 },
 { "point": 16325, "type": "fun", "name": "lq", "endpoint": 16484 },
 { "point": 16554, "type": "fun", "name": "setEqual", "endpoint": 16633 },
 { "point": 16636, "type": "fun", "name": "setSize", "endpoint": 16691 },
 { "point": 16694, "type": "fun", "name": "union", "endpoint": 16966 },
 { "point": 16988, "type": "fun", "name": "display", "endpoint": 17079 },
 { "point": 17082, "type": "fun", "name": "writeChar", "endpoint": 17138 },
 { "point": 17141, "type": "fun", "name": "newline", "endpoint": 17189 },
 { "point": 17192, "type": "fun", "name": "main", "endpoint": 17490 }
],
"config": {
 "hash": 53748832148537,
 "debug-client": 0,
 "tmp": "/tmp/serrano/J2S/maze.js",
 "optim-tyflow": true,
 "optim-uninit": true,
 "optim-inline": true,
 "optim-callapply": true,
 "optim-cspecs": true,
 "optim-multivar": true,
 "optim-cinstanceof": true,
 "optim-tyflow-resolve": true,
 "optim-unletrec": true,
 "optim-letopt": true,
 "optim-method": true,
 "optim-vector": true,
 "optim-ctor": true,
 "optim-range": true,
 "optim-hintnum": true,
 "optim-hint": true,
 "optim-array": true,
 "optim-literals": true,
 "optim-procedure": true,
 "optim-arguments": true,
 "optim-loopspec": true,
 "optim-globprop": true,
 "optim-inline-method": true,
 "optim-integer": true,
 "debug-stage": true,
 "commonjs-export": true,
 "return-as-exit": false,
 "filename": "maze.js",
 "driver-name": "j2s-optim-driver",
 "worker": true,
 "worker-slave": false,
 "module-main": true,
 "module-name": "maze",
 "module-path": false,
 "hopscript-header": true,
 "type-annotations": false,
 "optim": 1000,
 "verbose": 2,
 "long-size": 64,
 "int-size": 61,
 "plugins-loader": false,
 "libs-dir": false,
 "debug": 0,
 "function-nice-name": true,
 "profile-symbols": true,
 "profile-call": true,
 "profile-alloc": true,
 "optim-ccall": true,
 "es6-let": true,
 "es6-const": true,
 "es6-arrow-function": true,
 "es6-default-value": true,
 "es6-rest-argument": true,
 "es2017-async": true,
 "debug": 0
},
"run": {
 "HOPTRACE": "hopscript:call hopscript:symtable format:memviz j2s:loc",
 "commandline": "./a.out",
 "date": "Mon May 11 16:33:59 2020"
 }
}'
]
