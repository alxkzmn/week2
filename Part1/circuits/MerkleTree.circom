pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/gates.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    assert(n>0);

    component hashesByLevel[n][2**(n-1)];
    for (var l=n-1; l>=0; l--){
        for (var h=0; h<2**l; h++){
            hashesByLevel[l][h] = Poseidon(2);
            if (l==n-1){
                hashesByLevel[l][h].inputs[0] <== leaves[2*h];
                hashesByLevel[l][h].inputs[1] <== leaves[2*h+1];
            } else {
                hashesByLevel[l][h].inputs[0] <== hashesByLevel[l+1][2*h].out;
                hashesByLevel[l][h].inputs[1] <== hashesByLevel[l+1][2*h+1].out;
            }
        }
    }

    root <== hashesByLevel[1][0].out;
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    component hashes[n];
    component invertedPathIndex[n];
    signal invertedLeaf[n];
    signal invertedElement[n];
    for (var i = 0; i < n; i++){
        hashes[i] = Poseidon(2);
        invertedPathIndex[i] = NOT();
        invertedPathIndex[i].in <== path_index[i];
        invertedElement[i] <== invertedPathIndex[i].out * path_elements[i];
        if (i==0){
            invertedLeaf[i] <== invertedPathIndex[i].out * leaf;
            hashes[i].inputs[0] <== invertedLeaf[i] + path_elements[i] * path_index[i];
            hashes[i].inputs[1] <== path_index[i] * leaf + invertedElement[i];
        } else {
            invertedLeaf[i] <== invertedPathIndex[i].out * hashes[i-1].out;
            hashes[i].inputs[0] <== invertedLeaf[i] + path_elements[i] * path_index[i];
            hashes[i].inputs[1] <== path_index[i] * hashes[i-1].out + invertedElement[i];
        }
    }

    root <== hashes[n-1].out;
}