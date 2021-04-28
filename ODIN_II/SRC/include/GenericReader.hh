/*
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#ifndef __GENERIC_READER_H__
#define __GENERIC_READER_H__

#include "GenericIO.hh"

class VerilogReader;
class BLIFReader;

/**
 * @brief A class to provide the general object of an input file reader
*/
class GenericReader : public GenericIO {

    public:
        /**
         * @brief Construct the GenericReader object
         * required by compiler
         */
        GenericReader();
        /**
         * @brief Destruct the GenericReader object
         * to avoid memory leakage
         */
        ~GenericReader();

        void* read();

    private:
        VerilogReader*  verilog_reader;
        BLIFReader*     blif_reader;
        /**
         * [TODO]
         * SystemVerilog* systemverilog_reader;
         * ILangReader* ilang_reader;
        */

        void* read_verilog();
        void* read_blif();
        /**
         * [TODO]
         * void* read_systemverilog();
         * void* read_ilang(); 
         */

};

#endif