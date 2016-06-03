call "%VS140COMNTOOLS%..\..\VC\bin\amd64\cl.exe"
cmake %1 -DATOMIC_DEV_BUILD=1 -G "Visual Studio 14 2015 Win64"
msbuild Atomic.sln /m /p:Configuration=Debug /p:Platform=x64 /t:AtomicTool
