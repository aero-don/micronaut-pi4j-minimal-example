FROM arm64v8/fedora:34
COPY ./build/native-image/application /app/application
COPY ./lib/* /usr/local/lib/
RUN ln -s /usr/local/lib/libpigpio.so.1 /usr/local/lib/libpigpio.so
RUN ln -s /usr/local/lib/libpigpio_if.so.1 /usr/local/lib/libpigpio_if.so
RUN ln -s /usr/local/lib/libpigpio_if2.so.1 /usr/local/lib/libpigpio_if2.so
ENV LD_LIBRARY_PATH=/usr/local/lib
ENTRYPOINT ["/app/application", "-Dpi4j.library.path=/usr/local/lib"]
