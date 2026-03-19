# GitHub Actions + Workload Identity Federation

## Fix: Docker credential helper refresh failure with `gcloud auth configure-docker`

The credential helper runs as a child of the Docker daemon (root), so it does not inherit `GOOGLE_APPLICATION_CREDENTIALS` from the job. Copy the credentials to root's ADC path so the credential helper can find them.

### Add this step after Authenticate to GCP and before Configure Docker:

```yaml
- name: Make credentials available to Docker credential helper
  run: |
    sudo mkdir -p /root/.config/gcloud
    sudo cp "$GOOGLE_APPLICATION_CREDENTIALS" /root/.config/gcloud/application_default_credentials.json
```

### Full build-push job example:

```yaml
build-push:
  name: Build & Push Image
  needs: test
  runs-on: ubuntu-latest
  outputs:
    image: ${{ steps.meta.outputs.image }}
  steps:
    - uses: actions/checkout@v4

    - name: Authenticate to GCP
      uses: google-github-actions/auth@v2
      with:
        workload_identity_provider: ${{ secrets.GCP_WIF_PROVIDER }}
        service_account: ${{ secrets.GCP_DEPLOY_SA }}

    - name: Make credentials available to Docker credential helper
      run: |
        sudo mkdir -p /root/.config/gcloud
        sudo cp "$GOOGLE_APPLICATION_CREDENTIALS" /root/.config/gcloud/application_default_credentials.json

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: Configure Docker for Artifact Registry
      run: gcloud auth configure-docker ${{ env.REGION }}-docker.pkg.dev --quiet

    - name: Build and push
      uses: docker/build-push-action@v6
      with:
        context: .
        push: true
        tags: |
          ${{ env.REGION }}-docker.pkg.dev/${{ vars.GCP_PROJECT_ID }}/${{ vars.GAR_REPO }}/${{ vars.SERVICE_NAME }}:${{ github.sha }}
          ${{ env.REGION }}-docker.pkg.dev/${{ vars.GCP_PROJECT_ID }}/${{ vars.GAR_REPO }}/${{ vars.SERVICE_NAME }}:latest
        cache-from: type=gha
        cache-to: type=gha,mode=max

    - name: Set image output
      id: meta
      run: |
        IMAGE="${{ env.REGION }}-docker.pkg.dev/${{ vars.GCP_PROJECT_ID }}/${{ vars.GAR_REPO }}/${{ vars.SERVICE_NAME }}:${{ github.sha }}"
        echo "image=$IMAGE" >> "$GITHUB_OUTPUT"
```
