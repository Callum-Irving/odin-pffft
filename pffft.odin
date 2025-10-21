package pffft

import "core:c"
import "core:fmt"
import "core:math"
import "core:os"

foreign import lib "pffft/libpffft.a"

Setup :: distinct rawptr

Direction :: enum c.int {
	PFFFT_FORWARD = 0,
	PFFFT_BACKWARD,
}

Transform :: enum c.int {
	PFFFT_REAL = 0,
	PFFFT_COMPLEX,
}

@(default_calling_convention = "c", link_prefix = "pffft_")
foreign lib {
	// Prepare for performing transforms of size N -- the returned
	// PFFFT_Setup structure is read-only so it can safely be shared by
	// multiple concurrent threads.
	//
	// Will return NULL if N is not suitable (too large / no decomposable with simple integer
	// factors..)
	new_setup :: proc(n: c.int, transform: Transform) -> ^Setup ---
	destroy_setup :: proc(setup: ^Setup) ---

	// Perform a Fourier transform , The z-domain data is stored in the
	// most efficient order for transforming it back, or using it for
	// convolution. If you need to have its content sorted in the
	// "usual" way, that is as an array of interleaved complex numbers,
	// either use pffft_transform_ordered , or call pffft_zreorder after
	// the forward fft, and before the backward fft.
	//
	// Transforms are not scaled: PFFFT_BACKWARD(PFFFT_FORWARD(x)) = N*x.
	// Typically you will want to scale the backward transform by 1/N.
	//
	// The 'work' pointer should point to an area of N (2*N for complex
	// fft) floats, properly aligned. If 'work' is NULL, then stack will
	// be used instead (this is probably the best strategy for small
	// FFTs, say for N < 16384).
	//
	// input and output may alias.
	transform :: proc(setup: ^Setup, input, output, work: [^]c.float, direction: Direction) ---

	// Similar to pffft_transform, but makes sure that the output is
	// ordered as expected (interleaved complex numbers).  This is
	// similar to calling pffft_transform and then pffft_zreorder.
	//
	// input and output may alias.
	transform_ordered :: proc(setup: ^Setup, input, output, work: [^]c.float, direction: Direction) ---

	// call pffft_zreorder(.., PFFFT_FORWARD) after pffft_transform(...,
	// PFFFT_FORWARD) if you want to have the frequency components in
	// the correct "canonical" order, as interleaved complex numbers.
	//
	// (for real transforms, both 0-frequency and half frequency
	// components, which are real, are assembled in the first entry as
	// F(0)+i*F(n/2+1). Note that the original fftpack did place
	// F(n/2+1) at the end of the arrays).
	//
	// input and output should not alias.
	zreorder :: proc(setup: ^Setup, intput, output: [^]c.float, direction: Direction) ---

	// Perform a multiplication of the frequency components of dft_a and
	// dft_b and accumulate them into dft_ab. The arrays should have
	// been obtained with pffft_transform(.., PFFFT_FORWARD) and should
	// *not* have been reordered with pffft_zreorder (otherwise just
	// perform the operation yourself as the dft coefs are stored as
	// interleaved complex numbers).
	//
	// the operation performed is: dft_ab += (dft_a * fdt_b)*scaling
	//
	// The dft_a, dft_b and dft_ab pointers may alias.
	zconvolve_accumulate :: proc(setup: ^Setup, dft_a, dft_b, dft_ab: [^]c.float, scaling: c.float) ---

	// the float buffers must have the correct alignment (16-byte boundary
	// on intel and powerpc). This function may be used to obtain such
	// correctly aligned buffers.
	aligned_malloc :: proc(nb_bytes: c.size_t) -> rawptr ---
	aligned_free :: proc(_: rawptr) ---

	// return 4 or 1 wether support SSE/Altivec instructions was enable when building pffft.c
	simd_size :: proc() -> c.int ---
}

